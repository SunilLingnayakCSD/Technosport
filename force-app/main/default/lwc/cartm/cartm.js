import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import callSuitableMethod from '@salesforce/apex/InsertOrderMain.callSuitableMethod';
import BackIcon from '@salesforce/resourceUrl/BackIcon'
import DownArrow from '@salesforce/resourceUrl/DownArrow';
import id from '@salesforce/user/Id';

export default class Cartm extends LightningElement {
    BackIcon = BackIcon;
    DownArrow = DownArrow;
    @api recordid;
    
    @track userId = id;
    @api selectedProducts = [];
    @api distributoroptions
    // @api recordId;
    @track showimg = false;
    @track showMessege = false;
    @track showTable = false;
    @track products = [];
    @track productOptions;
    @track Quantity = new Map();
    @track selectedRows = [];
    @track showBlank = false;
    @track searchValue = '';
    @track allProducts = [];
    @track serializedSizes = [];
@track totalAmount=0
    renderedCallback() {
        this.initializeAccordion();
        
    }
    connectedCallback() {
        console.log('====================recordid================');
        console.log(this.recordid);
        
        console.log('====================================');
        console.log(JSON.stringify(this.selectedProducts),null,2);
        console.log('====================================');
        console.log('====================================');
        const totalRetailerPrice = this.selectedProducts.reduce((sum, item) => sum + (item.retailerPrice || 0), 0);
      this.totalAmount=totalRetailerPrice
      console.log('===============totalAmount=====================');
      console.log(this.totalAmount);
      console.log('====================================');

    }
   
    handleDecrement(event){
        this.updateQuantity(event, false);
    }
    handleIncrement(event){
        this.updateQuantity(event, true);
    }
    updateQuantity(event, isIncrement = true) {
        const id = event.target.dataset.id;
        const cart = event.target.dataset.cart;
        const cartqty = parseFloat(event.target.dataset.qty);
        let type=event.target.dataset.type
        let box=event.target.dataset.box
        let newQty= 1;
       
        console.log('===================cartqty=================');
        console.log(cartqty);
        console.log('====================================');
         newQty = isIncrement 
            ? cartqty + newQty 
            : cartqty - newQty;
    console.log('==============newQty======================');
    console.log(newQty);
    console.log('====================================');
        // Ensure quantity doesn't go negative
        if (newQty < 0) newQty = 0;
    
        // eslint-disable-next-line @lwc/lwc/no-api-reassignments
        this.selectedProducts = this.selectedProducts.map(item => {
            if (item.cartId === cart) {
                const updatedSizes = item.sizes.map(size => {
                    if (size.Id === id) {
                        return {
                            ...size,
                            Quantity__c: newQty
                        };
                    }
                    return size;
                });
              
                const totalQuantity = updatedSizes.reduce((sum, size) => sum + (size.Quantity__c || 0), 0);
                let totalPrice;
                if(item.type==='Catalogue'){

                     totalPrice = (totalQuantity*parseFloat(item.noofpieces)) * item.price;
                     console.log('====================================',type);
                     console.log(totalPrice);
                     console.log('====================================');
                }else{
                     totalPrice = totalQuantity * item.price;
                }
               
    
                return {
                    ...item,
                    sizes: updatedSizes,
                    total: totalQuantity,
                    retailerPrice: totalPrice
                };
            }
            return item;
        });
        const totalRetailerPrice = this.selectedProducts.reduce(
            (sum, items) => sum + (items.retailerPrice || 0), 
            0
        );
    
        this.totalAmount = totalRetailerPrice;
        
    
        console.log('================after quantity update====================');
        console.log(JSON.stringify(this.selectedProducts, null, 2));
        console.log('=========================================================');
    }
    
    
    @track distributorId;
    handleChange(event){
        this.distributorId=event.detail.value;
    }
    initializeAccordion() {
        const acc = this.template.querySelectorAll('.accordion');

        acc.forEach((element) => {
            element.addEventListener('click', () => {
                element.classList.toggle('active');

                const panel = element.nextElementSibling;

                if (panel) {
                    if (panel.style.display === 'block') {
                        panel.style.display = 'none';
                    } else {
                        panel.style.display = 'block';
                    }
                }
            });
        });
    }

    goBackToParent() {
        console.log('calling goBackToParent');
        const navigateBackEvent = new CustomEvent('navigateback');
        this.dispatchEvent(navigateBackEvent)
    }
    @api sendingArr = []
    handleDeleteRow(event) {

        const selectedId = event.target.dataset.id;
        console.log("selectedId:", selectedId);


        if (!Array.isArray(this.selectedProducts)) {
            console.error("selectedProducts is not an array or is undefined.");
            return;
        }

        console.log("Before filtering:", JSON.stringify(this.selectedProducts, null, 2));

        const filteredArray = this.selectedProducts.filter(item => item.cartId !== selectedId);


        console.log("After filtering:", JSON.stringify(filteredArray, null, 2));


        // eslint-disable-next-line @lwc/lwc/no-api-reassignments
        this.selectedProducts = filteredArray;

        console.log('=================handleDeleteRow===================');
        console.log(JSON.stringify(this.selectedProducts, null, 2));
        console.log('====================================');






        console.log('calling goBackToParent');

        const deleteSelectedInParent = new CustomEvent('deleteselectedinparent', {
            bubbles: true,
            composed: true,
            detail: { selected: selectedId }
        });

        console.log('Child: Event Detail', { selectedId });
        this.dispatchEvent(deleteSelectedInParent);

        console.log('Updated selectedProducts:', JSON.stringify(this.selectedProducts, null, 2));

    }


    handleSave() {
        if (this.selectedProducts.length === 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'No Items in Cart',
                    message: 'Please add items to cart',
                    variant: 'warning',
                })
            )
        } else {
            callSuitableMethod({ productsList: JSON.stringify(this.selectedProducts), recordId: this.userId, visitId: this.recordid, distributorId: this.distributorId })
                .then(result => {
                    console.log('Order Created Successfully:', result);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Order Captured',
                            message: 'New Order has been created successfully.',
                            variant: 'success',
                        })
                    );
                    this.distributorId=null         
                     window.location.reload();
                })
                .catch(error => {
                    console.error('Error creating order:', error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error Creating Order',
                            message: error.body.message,
                            variant: 'error',
                        })
                    );
                });
        }


    }
  
}