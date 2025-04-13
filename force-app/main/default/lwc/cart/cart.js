import { LightningElement, api, track,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CreateOrder from '@salesforce/apex/InsertOrder.CreateOrder';
import BackIcon from '@salesforce/resourceUrl/BackIcon'
import DownArrow from '@salesforce/resourceUrl/DownArrow';
import id from '@salesforce/user/Id';
import { NavigationMixin } from 'lightning/navigation';

export default class Cart extends NavigationMixin(LightningElement) {
    BackIcon=BackIcon;
    DownArrow=DownArrow;
    @track userId=id;
    @api selectedProducts=[]; 
    @api recordId;
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
 
    renderedCallback() {
        this.initializeAccordion();
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
    @api sendingArr=[]
    handleDeleteRow(event) {
      
        const selectedId = event.target.dataset.id; 
        console.log( "selectedId:", selectedId);
    
       
        if (!Array.isArray(this.selectedProducts)) {
            console.error("selectedProducts is not an array or is undefined.");
            return;
        }
   
        console.log("Before filtering:", JSON.stringify(this.selectedProducts, null, 2));

        const filteredArray = this.selectedProducts.filter(item => item.cartId !== selectedId);
    
     
        console.log("After filtering:", JSON.stringify(filteredArray, null, 2));
    
        
        this.selectedProducts =filteredArray; 
    
        console.log('=================handleDeleteRow===================');
        console.log(JSON.stringify(this.selectedProducts, null , 2));
        console.log('====================================');
       
    
      
    
    
        
        console.log('calling goBackToParent');

        const deleteSelectedInParent = new CustomEvent('deleteselectedinparent', {
            bubbles: true,
            composed: true,
            detail: {selected: selectedId} 
        });
      
        console.log('Child: Event Detail', { selectedId });
        this.dispatchEvent(deleteSelectedInParent);
        
        console.log('Updated selectedProducts:', JSON.stringify(this.selectedProducts, null, 2));
    
    }

    
    handleSave(){
        if(this.selectedProducts.length===0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'No Items in Cart',
                    message: 'Please add items to cart',
                    variant: 'warning',
                })
            )
        }else{
        CreateOrder({ productsList: JSON.stringify(this.selectedProducts), recordId: this.userId })
        .then(result => {
                        console.log('Order Created Successfully:', result);
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Order Captured',
                                message: 'New record has been created successfully.',
                                variant: 'success',
                            })
                        );
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
handleBundleQuantitychange(event){
    let quantityValue= event.target.value;
    let cartId=event.target.dataset.id
    console.log('==============quantityValue======================');
    console.log(quantityValue,'********',cartId);
    console.log('====================================');

    this.selectedProducts = this.selectedProducts.map(item => 
        item.cartId === cartId ? { ...item, quantity: parseFloat(quantityValue) } : item
    );
    console.log('====================update cart details================',cartdetails.quantity);
    
    console.log(JSON.stringify(this.selectedProducts) );
    console.log('====================================');
   
}

}