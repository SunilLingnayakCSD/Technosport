import { LightningElement, wire, track, api } from 'lwc';
import getRecentProducts from '@salesforce/apex/NewlaunchesProduct.getRecentProducts';
import image1 from '@salesforce/resourceUrl/image1';
import img1 from '@salesforce/resourceUrl/img1';
import img2 from '@salesforce/resourceUrl/img2';
import img3 from '@salesforce/resourceUrl/img3';
import lead from '@salesforce/resourceUrl/lead';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAccountsForLoggedInUser from '@salesforce/apex/ProductController.getAccountsForLoggedInUser'
import createOrUpdateDistributorProductInterest from '@salesforce/apex/DistributorProductInterestController.createOrUpdateDistributorProductInterest'
import userId from '@salesforce/user/Id'
import deleteFromCart from '@salesforce/apex/CartController.deleteFromCart'
import insertCarts from '@salesforce/apex/CartController.insertCarts'
import getAllCartItems from '@salesforce/apex/CartController.getAllCartItems'
import getInvoicesForLoggedInUserdue from '@salesforce/apex/InvoiceControllerForPortal.getInvoicesForLoggedInUserdue';
import LightningAlert from 'lightning/alert';


import DownArrow from '@salesforce/resourceUrl/DownArrow';
export default class NewLaunches extends NavigationMixin(LightningElement) {
    @api products;
    image1 = image1;
    img1 = img1
    img2 = img2
    img3 = img3
    lead = lead
    @track userid = userId
    DownArrow = DownArrow;
    @track ismodalopen = false
    @track colorOptions = []

    @track sizes = {};
    @track products = [];
    @track error;
    @track showsizes = true;
    options = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' },
    ];
    connectedCallback() {
        this.fetchInvoices();
        this.fetchRecentProducts()
        this.getAllcartDetailsFromAccount()
        this.getAccountsForLoggedInUsermethod();
        
        
    }
    @track accountDetails
    @track threshholdAmount;
    @track totalResidualAmount
    getAccountsForLoggedInUsermethod() {
        getAccountsForLoggedInUser({ recordId: this.userid }).then(result => {
            this.accountDetails = result
            console.log('===================accountDetails=================');
            console.log(JSON.stringify(this.accountDetails));
            console.log('====================================');
            this.threshholdAmount = this.accountDetails[0].Overdue_Threshold_Limit__c
            this.totalResidualAmount = this.accountDetails[0].Total_Invoice_Amount__c
            this.threshholddays=this.accountDetails[0].Threshold_days__c
            let number = this.threshholddays.match(/\d+/);
             this.dayss=number !=null?number[0]:0
            console.log('===================days=================');
            console.log(this.dayss,this.threshholdAmount, this.totalResidualAmount);
            console.log('====================================');
            if (this.totalResidualAmount>=this.threshholdAmount &&this.getDueDate() > this.getDatePlus15Days()){
                LightningAlert.open({
                    message: 'Your invoice is overdue. Please make the payment.',
                    theme: 'warning', // Possible values: 'info', 'success', 'error', 'warning'
                    label: 'Overdue Invoice'
                   
                });
            }
        }).catch(error => {
            console.log(error);

        })
    }
    getDatePlus15Days() {
        const today = new Date();
        today.setDate(today.getDate() ); // Add 15 days

        const year = today.getFullYear();
        const month = String(today.getMonth() + 1).padStart(2, '0');
        const day = String(today.getDate()).padStart(2, '0');
        console.log('================15 days date====================');
        console.log(`${year}-${month}-${day}`);
        console.log('====================================');
        return `${year}-${month}-${day}`;
    }
    getDueDate() {
        
        if (!(this.duedateForLastInvoice instanceof Date)) {
            this.duedateForLastInvoice = new Date(this.duedateForLastInvoice); 
        }
    
        this.duedateForLastInvoice.setDate(this.duedateForLastInvoice.getDate() + this.dayss);
    
        const year = this.duedateForLastInvoice.getFullYear();
        const month = String(this.duedateForLastInvoice.getMonth() + 1).padStart(2, '0');
        const day = String(this.duedateForLastInvoice.getDate()).padStart(2, '0');
    
        console.log('================15 days date====================');
        console.log(`${year}-${month}-${day}`);
        console.log('====================================');
    
        return `${year}-${month}-${day}`;
    }
    checkConditions(){
     if(this.threshholdAmount===0 ||this.totalResidualAmount===0){
            return true;
        }
        else if(this.threshholdAmount >= this.totalResidualAmount){
           return true;
       }else if(this.getDueDate() > this.getDatePlus15Days()){
           return true
       }
          return false
   }
    @track invoices
    @track duedateForLastInvoice

    fetchInvoices() {
        getInvoicesForLoggedInUserdue()
            .then((data) => {
                if (data && data.length > 0) {
                    console.log('=============invoice method=======================');
                    console.log(data);
                    console.log('====================================');
                    this.duedateForLastInvoice = data[0]?.Due_Date__c || null;
                    console.log('==============duedateForLastInvoice======================');
                    console.log(this.duedateForLastInvoice);
                    console.log('====================================');
                    console.log('================this.threshholdAmount ====================');
                    console.log(this.threshholdAmount );
                    console.log('====================================');
                    console.log('=============this.totalResidualAmount=======================');
                    console.log(this.totalResidualAmount);
                    console.log('====================================');
                   
                    this.error = undefined;
                } else {
                    console.warn('No invoices returned');
                    this.duedateForLastInvoice = null;
                    this.error = undefined;
                }
            })
            .catch((error) => {
                this.error = error.body ? error.body.message : 'Unknown error occurred';
                this.duedateForLastInvoice = null;
                console.error('Error fetching invoices:', JSON.stringify(error));
            });
    }
  
    getAllcartDetailsFromAccount() {
        getAllCartItems({ recordId: this.userid }).then(result => {
            this.selectedProductsVarient = result.map(item => {
                return {
                    cartId: item.Id,
                    Id: item.Product__c != null ? item.Product__c : null,
                    name: item.Name != null ? item.Name : null,
                    price: item.Unit_Price__c != null ? item.Unit_Price__c : 0,
                    imageUrl: item.Image_URL__c != null ? item.Image_URL__c : null,
                    boxes: item.Boxes__c != null ? item.Boxes__c : 0,
                    quantity: item.Bundle_Quantity__c != null ? item.Bundle_Quantity__c : 0,
                    type: item.Product_type__c != null ? item.Product_type__c : '',
                    total: item.Total__c != null ? item.Total__c : 0,
                    sizes: item.Cart_Items__r != null ? item.Cart_Items__r.map(size => ({
                        ...size,
                        statusLabel: size.isUpcomingVarient__c ? 'Upcoming' : 'Current'
                    })) : [], 
                    isFutureProduct: item.isFutureProduct__c,
                    isFutureQuoShouuldteCreate: item.isFutureQuoShouuldteCreate__c
                }
            })
            console.log('===========defaultcart=========================');
            console.log(JSON.stringify(this.selectedProductsVarient, null, 2));
            console.log('====================================');
        })

    }
    @track cart = false;
    @track displaymain = true
    handleCartClick() {
        if (this.selectedProductsVarient.length > 0) {
            console.log('Sending data to child************************8:', JSON.stringify(this.selectedProductsVarient));
            this.cart = true;
            this.displaymain = false


        } else {

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    message: 'Please select atleast one product',
                    variant: 'Error',
                })
            );
            this.cart = false;
        }
    }
    handleNavigateBack() {

        console.log('Navigating back to parent');
        this.cart = false;
        this.displaymain = true
        // this.template.querySelector('.main').style.display = 'block'
        //this.products = this.catalogueProducts != null ? this.catalogueProducts : this.AllProducts;

    }
    handleDeleteSelectedInParent(event) {

        const selectedId = event.detail.selected;
        console.log('=================selectedId===================');
        console.log(selectedId);
        console.log('====================================');
        deleteFromCart({ cartId: selectedId, recordId: this.userid }).then(result => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Item has been removed from cart.',
                    variant: 'success',
                })
            )
         //   this.selectedProductsVarient = this.selectedProductsVarient.filter(item => item.id !== selectedId)
        }).catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Something went wrong',
                    variant: 'error',
                })
            )
        })
    }
    renderedCallback() {
        this.initializeAccordion();
    }

    initializeAccordion() {

        const acc = this.template.querySelectorAll('.accordion');

        if (acc.length > 0) {
            acc.forEach((element) => {

                if (!element.hasAttribute('data-listener')) {
                    element.addEventListener('click', () => this.toggleAccordion(element));

                    element.setAttribute('data-listener', 'true');
                }
            });
        }
    }

    toggleAccordion(element) {

        element.classList.toggle('active');

        const panel = element.nextElementSibling;

        if (panel) {
            panel.classList.toggle('show');
        }
    }
    /////////////////////////////////////////////////////////
    handleInterested(event) {
        const productId = event.target.dataset.id;
        console.log('Interested product ID:', productId);

        const product = this.products.find(item => item.Id === productId);
        console.log('Interested product:', JSON.stringify(product));

        const isInterested = event.detail.value;
        product.interested = isInterested !== null ? isInterested : null;

        console.log('Selected interest:', product.interested);

        createOrUpdateDistributorProductInterest({
            productId: productId,
            areYouInterested: product.interested,
            recordId: this.userid
        })
            .then(result => {
                console.log('Apex call success:', result);
            })
            .catch(error => {
                console.error('Apex call error:', JSON.stringify(error));
                if (error.body) {
                    console.error('Error details:', error.body);
                    if (error.body.fieldErrors) {
                        console.error('Field Errors:', JSON.stringify(error.body.fieldErrors));
                    }
                    if (error.body.pageErrors) {
                        console.error('Page Errors:', JSON.stringify(error.body.pageErrors));
                    }
                }
            });

    }
    @track sizesvar
    handleSizeInput(event) {
        const productId = event.target.dataset.id;
        const varId = event.target.dataset.varid;
        const size = event.target.dataset.size;
   
        const quantity = isNaN(parseFloat(event.target.value)) ? 0 : parseFloat(event.target.value);
    
        if (!this.sizes[productId]) {
            this.sizes[productId] = {};
        }
    
        if (!this.sizes[productId][size]) {
            this.sizes[productId][size] = {};
        }

        this.sizes[productId][size][varId] = quantity;
    
        let totalQuantity = 0;
        for (const sizeKey in this.sizes[productId]) {
            if (this.sizes[productId].hasOwnProperty(sizeKey)) { 
                for (const varKey in this.sizes[productId][sizeKey]) {
                    if (this.sizes[productId][sizeKey].hasOwnProperty(varKey)) { 
                        const variantQuantity = this.sizes[productId][sizeKey][varKey];
    
                     
                        if (!isNaN(variantQuantity)) {
                            totalQuantity += variantQuantity;
                    }
                }
            }
            }
        }
    
      
        const product = this.products.find(i => i.Id === productId);
        if (product) {
            product.total = totalQuantity; 
            console.log('Product with updated total:', product.total);
        } else {
            console.error('Product not found');
        }
    }
    
    handleQuantityInput(event) {
        const productId = event.target.dataset.id
        const qty = this.products.find(item => item.Id === productId)
        const newQuantity = event.target.value;
        const reserveBundle = event.target.value;
        console.log('====================================');
        console.log(newQuantity);
        console.log('====================================');
        qty.quantity = newQuantity;
        this.products = [...this.products];
        console.log('================qty.quantity====================');
        console.log(qty.quantity);
        console.log('====================================');
        console.log('ReserveBundle' + reserveBundle);

    }
   
    catalougeproductSelected(event) {

        if (this.checkConditions()===true) {
            
            
                const productId = event.currentTarget.dataset.id;
                const selectedpro=this.products.find(item=>item.Id===productId)
              if(selectedpro.interested !==null){
                const qty = event.target.dataset.qty
                console.log('Product ID:', productId);
                const productName = event.currentTarget.dataset.name;
                const productPrice = event.currentTarget.dataset.price;
                const productImageUrl = event.currentTarget.dataset.imageurl;
                console.log('productImageUrl--------------------->', productImageUrl);
                const productBoxes = event.currentTarget.dataset.boxes;
                const quantity = qty !== null ? qty : 0;
                console.log('productBoxes---------------------------------->', productBoxes);


                const productVariant = event.currentTarget.dataset.variant;
                const pricebookEntryId = event.currentTarget.dataset.priceentryid;
                console.log('pricebookEntryId', pricebookEntryId);

                const selectedSizes = this.sizes[productId] || {};
                console.log('==============selectedSizes======================');
                console.log(selectedSizes);
                console.log('====================================');
                console.log('Selected Sizes for Product:', selectedSizes);


                const variant = {
                    id: productId,
                    name: productName,
                    price: productPrice,
                    imageUrl: productImageUrl,
                    variant: productVariant,
                    sizes: selectedSizes,
                    boxes: productBoxes,
                    quantity: Number(quantity),
                    pricebookEntryId: pricebookEntryId,
                    type: 'Catalogue',
                    isFutureProduct: false,
                isFutureQuoShouuldteCreate: false

                };

                console.log('Variant:', JSON.stringify(variant.boxes));
                console.log('Variant:', JSON.stringify(variant));

                let total = 0
                let boxQty = productBoxes != null ? parseInt(productBoxes, 10) : 0;
                console.log('==============boxQty======================');
                console.log(boxQty);
                console.log('====================================');
                Object.keys(selectedSizes).forEach(size => {
                    const variants = selectedSizes[size];
                    Object.keys(variants).forEach(varId => {
                        const quantityForVariant = parseInt(variants[varId], 10);
                        console.log(`Size: ${size}, Variant: ${varId}, Quantity: ${quantityForVariant}`);

                        if (quantityForVariant > 0) {
                            total += quantityForVariant;
                            variant.sizes[size][varId] = { quantity: quantityForVariant, color: '',isUpcomingVariant: false };
                            variant.quantity = Number(quantity)
                            variant.total = total
                            console.log('==============total======================');
                            console.log(total);
                            console.log('====================================');
                        }
                    });
                });

                let productExists = this.selectedProductsVarient.some(item => item.id == productId);
                if (productExists) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error!',
                            message: 'This product is already added to the cart.',
                            variant: 'error',
                        })
                    );
                    return;
                }
                if (Object.keys(variant.sizes).length > 0 && variant.quantity > 0) {
                    console.log('=========checktotal===========================');
                    console.log(variant.total, boxQty);
                    console.log('====================================');
                    if (variant.total === boxQty) {
                        console.log('================variant====================');
                        console.log(variant);

                        console.log('====================================');
                        //  this.selectedProductsVarient.push(variant);
                        insertCarts({ cartData: variant, recordId: this.userid }).then(result => {
                            console.log('===============cart result=====================');
                            console.log(result);
                            console.log('====================================');
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Added!',
                                    message: 'Item has been added successfully to cart.',
                                    variant: 'success',
                                })
                            );
                            const recivedres=result != null ? result.sizes.map(size => ({
                                ...size,
                                statusLabel: size.isUpcomingVarient__c ? 'Upcoming' : 'Current'
                            })) : []
                            result.sizes=recivedres;
                            this.selectedProductsVarient.push(result)
                            console.log('===============this.cartlength=====================');
                            console.log(this.cartlength);
                            console.log('====================================');


                        }).catch(error => {
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Error!',
                                    message: 'Something went wrong. Please try again.', error,
                                    variant: 'error',
                                })
                            );
                            console.log('====================================');
                            console.log(error);
                            console.log('====================================');
                        })

                    } else {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error!',
                                message: 'Total Item Quantity is should be equals to Box quantity.',
                                variant: 'error',
                            })
                        );
                    }

                } else {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error!',
                            message: 'Quantity and Bundle Quantity Should be more than Zero.',
                            variant: 'error',
                        })
                    );
                }

                console.log('*********************Selected Variants:', this.selectedProductsVarient);
            // } else {
            //     this.dispatchEvent(
            //         new ShowToastEvent({
            //             title: 'Error!',
            //             message: 'The order cannot be placed because the due date limit has been exceeded.',
            //             variant: 'error',
            //         })
            //     );
            // }
        }else{
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    message: 'Please Select the Product Intrest.',
                    variant: 'Error',
                })
            );
          }
             
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    message: 'Order cannot be placed as outstanding invoices exceed the limit.',
                    variant: 'Error',
                })
            );
        }
   

    }


    ///////////////////////////////////////////

    @track rowOffset = 0;
    rowLimit = 4;
    @track isLoading = false;
    @track selectedProductsVarient = []

    fetchRecentProducts() {
        this.isLoading = true;
        getRecentProducts({ rowlimit: this.rowLimit, offset: this.rowOffset })
            .then(result => {
                const mappedArray = result.map(product => {
                    const price = product.PricebookEntries && product.PricebookEntries.length > 0
                        ? product.PricebookEntries[0].UnitPrice
                        : 0;
                    const pricebookEntryId = product.PricebookEntries && product.PricebookEntries.length > 0
                        ? product.PricebookEntries[0].Id
                        : '';
                    const productBoxes = product.Boxes__c !== null ? product.Boxes__c : 0
                    const availabledate = product.Next_Available_Date__c
                    let varients = product.Products1__r && product.Products1__r.length > 0 ? product.Products1__r : []
                    varients = varients.map((item) => {
                        let invfreeqty = 0;
                        if (item.Inventories__r && item.Inventories__r.length > 0) {
                            invfreeqty = item.Inventories__r[0].Free_Quantity__c >= 50 
                                ? 50 
                                : item.Inventories__r[0].Free_Quantity__c;
                        }
                    
                        return {
                            ...item,
                            freeqty: invfreeqty
                        };
                    });
                    const baseUrl = window.location.origin;
                    const pdfurl=product.pdfUrls !=null?product.pdfUrls[0] :null;
                    console.log('pdfurl',pdfurl);
                    
                    return {
                        Id: product.Id,
                        Name: product.Name,
                        ImageUrl: product.Image_url__c,
                        VideoUrl: product.Video_Url__c,
                        Category: product.cgcloud__Category__c,
                        CreatedDate: product.CreatedDate,
                        boxes: productBoxes,
                        pricebookEntryId: pricebookEntryId,
                        quantity: 0,
                        Price: price,
                        interested: null,
                        varients: varients,
                        total: 0,
                        noofpieces: product.Number_of_pieces_in_Box__c,
                        availabledate: availabledate,
                        isFutureProduct: false,
                        pdfurl:String(baseUrl+pdfurl)
                    };
                });
                console.log('============insisdeeeeeeeeeeeeee========================');
                console.log('inside');
                console.log('====================================');
                this.products = [...this.products, ...mappedArray]
                console.log('====================================');
                console.log(JSON.stringify(this.products, null, 2));
                console.log('====================================');
                this.rowOffset += this.rowLimit;
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error;
                this.isLoading = false;
                console.error('Error fetching recent products:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error fetching recent products',
                        message: error.getMessage(),
                        variant: 'error',
                    }),
                )
            });
    }

    handleScroll(event) {
        const bottomOfList = event.target.scrollWidth - event.target.scrollLeft - event.target.clientWidth <= 1;

        if (bottomOfList && !this.isLoading) {
            this.fetchRecentProducts();
        }
    }

}