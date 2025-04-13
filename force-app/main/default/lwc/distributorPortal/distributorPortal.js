import { LightningElement, track, wire } from 'lwc';
import techno from '@salesforce/resourceUrl/techno';
import BackIcon from '@salesforce/resourceUrl/BackIcon';
import DownArrow from '@salesforce/resourceUrl/DownArrow';
import getProducts from '@salesforce/apex/ProductController.getProducts';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getInvoicesForLoggedInUser from '@salesforce/apex/InvoiceControllerForPortal.getInvoicesForLoggedInUser';
import getAccountsForLoggedInUser from '@salesforce/apex/ProductController.getAccountsForLoggedInUser'
import Id from '@salesforce/user/Id'
import insertCarts from '@salesforce/apex/CartController.insertCarts'
import getAllCartItems from '@salesforce/apex/CartController.getAllCartItems'
import deleteFromCart from '@salesforce/apex/CartController.deleteFromCart'
export default class DistributorPortal extends LightningElement {
    userId = Id
    scrollingMessage = [];
    @track accountDetails
    @track threshholdAmount;
    @track totalResidualAmount
    @track threshholddays;
    days
    getAccountsForLoggedInUsermethod() {
        getAccountsForLoggedInUser({ recordId: this.userId }).then(result => {
            this.accountDetails = result
            this.threshholdAmount = this.accountDetails[0].Overdue_Threshold_Limit__c
            this.totalResidualAmount = this.accountDetails[0].Total_Invoice_Amount__c
            this.threshholddays=this.accountDetails[0].Threshold_days__c
            let number = this.threshholddays.match(/\d+/);
             this.dayss=number !=null?number[0]:0
            console.log('===================days=================');
            console.log(this.dayss);
            console.log('====================================');
        }).catch(error => {
            console.log(error);

        })
    }

    @track invoices
    @track duedateForLastInvoice

    fetchInvoices() {
        getInvoicesForLoggedInUser()
            .then((data) => {
                if (data && data.length > 0) {
                    this.duedateForLastInvoice = data[0]?.Due_Date__c || null;
                    console.log('==============duedateForLastInvoice======================');
                    console.log(this.duedateForLastInvoice);
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
    getDatePlus15Days() {
        const today = new Date();
        today.setDate(today.getDate());
        const year = today.getFullYear();
        const month = String(today.getMonth() + 1).padStart(2, '0');
        const day = String(today.getDate()).padStart(2, '0');
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
    @track rows = [];
    @track colorOptions = []
    @track SelectedColor = ''
    @track cart = false;
    @track products = false;
    techno = techno;
    BackIcon = BackIcon;
    DownArrow = DownArrow;
    @track products = [];
    @track isLoading = true;
    @track selectedVariants = [];
    @track isVariantView = false;
    @track counter = 0;
    @track arr = [];
    @track selectedProductsVarient = [];
    @track sizes = {};
    @track filterType = [];
    @track filteredProducts = [];
    @track pickval = "CATALOUGE PRODUCT"
    @track selectedProduct = null;
    @track categoryval;
    @track AddCartVisible = true;
    @track removeBtnVisible = false;
    @track ViewOnProductvarient = false;
    @track quantityValue = 0;
    @track showCatalogueButton = true;
    @track removeCatalogueButton = false;
    @track selectedFilter = [];
    @track showsizes = true;
    @track showsizes1 = false;
    @track filteredProducts1 = [];
    @track selectingProducts = false;
    @track ismodalopen = false;
    @track selectedProduct1 = {};
    subscription = null;

    connectedCallback() {
        this.fetchInvoices()
        this.getdefaultProducts();
        this.getAccountsForLoggedInUsermethod()
        this.getAllcartDetailsFromAccount();
       
    }
    getAllcartDetailsFromAccount() {
        getAllCartItems({ recordId: this.userId }).then(result => {
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
                    sizes: item.Cart_Items__r != null ? item.Cart_Items__r : []
                }
            })
        })

    }

    handleQuantityAndSize(event) {
        const productId = event.target.dataset.id;
        const size = event.target.dataset.size;
        const key = event.target.dataset.varid;
        const color = event.target.dataset.color;
        const value = parseFloat(event.target.value);
        const row = this.rows.find(r => r.productId === productId);
        if (!row.sizes) {
            row.sizes = {};
        }

        if (!row.sizes[size]) {
            row.sizes[size] = {};
        }

        row.sizes[size][key] = { quantity: value, color: color };
        let totalQuantity = 0;


        for (const sizeKey in row.sizes) {
            if (row.sizes.hasOwnProperty(sizeKey)) {
                for (const varKey in row.sizes[sizeKey]) {
                    totalQuantity += row.sizes[sizeKey][varKey].quantity || 0;
                }
            }
        }

        row.quantity = totalQuantity;
    }

    handleQuantityInputChnge(event) {
        const productId = event.target.dataset.id;
        const value = event.target.value;
        const key = event.target.dataset.key;

        const row = this.rows.find(row => row.key == key);
        if (!row) {
            console.error('Row not found for productId:', key);
            return;
        }


        row.bundlequantity = value;

        console.log('Updated Rows:', JSON.stringify(this.rows));
    }

    handleQuantityChange(event) {
        const index = event.target.dataset.id;
        const value = event.detail.value;
        const key = parseInt(event.target.dataset.key, 10);
        this.rows[key].quantity = value;

    }
    @track cartlength
    addToCart() {
        console.log('====================================');
        console.log(this.threshholdAmount, '*******', this.totalResidualAmount);
        console.log('====================================');

        if (this.checkConditions() === true) {
            const sizeInputs = this.template.querySelectorAll('.size-input');
            const selectedItems = [];
            
            sizeInputs.forEach(input => {
                const quantity = parseInt(input.value) || 0;
                if (quantity > 0) {
                    selectedItems.push({
                        size: input.dataset.size,
                        quantity: quantity,
                        color: input.dataset.color,
                        productTemplateId: input.dataset.id,
                        variantId: input.dataset.varid
                    });
                    
                }
            });
            if (selectedItems.length === 0) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error!',
                        message: 'Please enter quantity for at least one size.',
                        variant: 'error',
                    })
                );
                return;
            }
           
            console.log("Selected items before adding to cart:", selectedItems);
            const sizesObject = {};
            selectedItems.forEach(item => {
                if (!sizesObject[item.size]) {
                    sizesObject[item.size] = {};
                }
                sizesObject[item.size][item.variantId] = {
                    quantity: item.quantity,
                    color: item.color
                };
            });

            const calculatedQuantity = selectedItems.reduce((total, item) => total + item.quantity, 0);
            const cartItem = {
                id: this.selectedProduct.id,
                name: this.selectedProduct.name,
                price: this.selectedProduct.price || 0,
                sizes: sizesObject,
                quantity: calculatedQuantity,
                imageUrl: this.selectedProduct.imageUrl,
                color: this.selectedProduct.color,
                pricebookEntryId: this.selectedProduct.priceEntryId,
                boxes: this.selectedProduct.boxes != null ? String(this.selectedProduct.boxes) : String('0'),
                bundlequantity: this.selectedProduct.bundlequantity != null ? this.selectedProduct.bundlequantity : 0,
                type: this.selectedProduct.type || 'Blank',
                total:  calculatedQuantity
            };
            insertCarts({ cartData: cartItem, recordId: this.userId })
                .then(result => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Added!',
                            message: 'Item has been added successfully to cart.',
                            variant: 'success',
                        })
                    );

                    this.selectedProductsVarient.push(result);
                    this.cartlength = result;
                    this.ismodalopen = false;
                    sizeInputs.forEach(input => {
                        if (parseInt(input.value) > 0) {
                            input.value = '';
                        }
                    });
                })
                .catch(error => {
                    console.error('Cart addition error:', error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error!',
                            message: error.body?.message || 'Something went wrong. Please try again.',
                            variant: 'error',
                        })
                    );
                });
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!',
                    message: 'Order cannot be placed as outstanding invoices exceed the limit.',
                    variant: 'error',
                })
            );
        }
    }

    get background() {
        return `background-image: url(${this.downArrowUrl}); background-repeat: no-repeat; background-position: right center; padding-right: 30px;`;
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
    @track AllProducts
    @track catalogueProducts
    @track rowOffset = 0;
    rowLimit = 400;
    isDataComplete = false;
    getdefaultProducts() {
        this.isLoading = true;
        getProducts({
            filterValue: this.pickval,
            categoryValue: this.categoryval,
            limitSize: this.rowLimit,
            offset: this.rowOffset
        })
            .then(result => {
                if (result.length === 0) {
                    this.isDataComplete = true;
                }
                this.products = [...this.products, ...result.map(product => {
                    const price = product.PricebookEntries && product.PricebookEntries.length > 0
                        ? product.PricebookEntries[0].UnitPrice
                        : 0;
                    const imageUrl = product.Image_url__c;
                    const videoUrl = product.Video_Url__c;
                    const Productcategory = product.Product_Category__c;
                    const pricebookEntryId = product.PricebookEntries && product.PricebookEntries.length > 0
                        ? product.PricebookEntries[0].Id
                        : '';
                    const boxes = product.Boxes__c != null ? product.Boxes__c : 0;
                    const varients = product.Products1__r && product.Products1__r.length > 0 ? product.Products1__r : []
                    return {
                        Id: product.Id,
                        Name: product.Name,
                        Price: price,
                        ImageUrl: imageUrl != null ? imageUrl : '',
                        videourl: videoUrl,
                        boxes: boxes,
                        Type: product.cgcloud__Category__c,
                        pCategory: Productcategory,
                        pricebookEntryId: pricebookEntryId,
                        quantity: 0,
                        total: 0,
                        varients: varients,
                        noofpieces: product.Number_of_pieces_in_Box__c
                    };
                })];


                this.rowOffset += this.rowLimit;
                this.AllProducts = this.products
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error filtering products:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error!',
                        message: 'Error filtering products.',
                        variant: 'Error',
                    })
                );
                this.isLoading = false;
            });
    }
    handleScroll(event) {
        // const bottomOfList = event.target.scrollHeight === event.target.scrollTop + event.target.clientHeight;
        let bottomOfList = event.target.scrollHeight - event.target.scrollTop <= event.target.clientHeight + 10;
        if (bottomOfList && !this.isLoading && !this.isDataComplete) {
            this.getdefaultProducts();

        }
    }
    getProductsBasedOnCondition(filterval, categoryval) {
        this.isLoading = true;
        console.log('Fetching products for filter:', filterval, 'category:', categoryval);
        getProducts({
            filterValue: filterval,
            categoryValue: categoryval,
            limitSize: this.rowLimit,
            offset: this.rowOffset
        })
            .then(data => {

                if (data.length === 0) {
                    this.isDataComplete = true;
                } else {
                    this.products = [...this.products, ...data.map(product => {
                        const price = product.PricebookEntries && product.PricebookEntries.length > 0
                            ? product.PricebookEntries[0].UnitPrice
                            : 0;
                        const imageUrl = product.Image_url__c != null ? product.Image_url__c : '';
                        const category = product.cgcloud__Category__c;
                        const Productcategory = product.Product_Category__c;
                        const pricebookEntryId = product.PricebookEntries && product.PricebookEntries.length > 0
                            ? product.PricebookEntries[0].Id
                            : '';
                        const varients = product.Products1__r && product.Products1__r.length > 0 ? product.Products1__r : [];

                        return {
                            Id: product.Id,
                            Name: product.Name,
                            Price: price,
                            ImageUrl: imageUrl,
                            Type: category,
                            pCategory: Productcategory,
                            boxes: product.Boxes__c !== null ? product.Boxes__c : 0,
                            pricebookEntryId: pricebookEntryId,
                            quantity: 0,
                            total: 0,
                            varients: varients,
                            noofpieces: product.Number_of_pieces_in_Box__c
                        };
                    })];

                    this.rowOffset += this.rowLimit;
                }

                this.filteredProducts = [...this.products];
                this.catalogueProducts = this.products;
                this.cart = false;
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error filtering products:', error);
                this.isLoading = false;
            });
    }
    handleCategoryChange(event) {

        event.preventDefault();
        const category = event.target.dataset.category;
        if (category) {
            this.products = [];
            this.rowOffset = 0;
            this.categoryval = category;
            this.getProductsBasedOnCondition(this.pickval, this.categoryval)
        }
    }

    handleFilterChange(event) {
        this.selectedFilter = event.target.value;
        this.products = [];
        this.rowOffset = 0;
        if (this.selectedFilter === 'CATALOUGE PRODUCT') {
            this.showCatalogueButton = true;
            this.showsizes = true;
            this.showsizes1 = false;
            this.selectingProducts = false;

        } else if (this.selectedFilter === 'BLANKS PRODUCT') {
            this.showCatalogueButton = false;
            this.selectingProducts = true;
            this.showsizes1 = false;
            this.showsizes = false;

        }
        this.pickval = this.selectedFilter
        this.getProductsBasedOnCondition(this.pickval, this.categoryval)
    }
    searchProduct(event) {
        const searchKey = event.target.value.toLowerCase();

        // if (searchKey.length > 0 && this.pickval === "CATALOUGE PRODUCT") {
        //     this.products = this.AllProducts.filter(product =>
        //         product.Name.toLowerCase().includes(searchKey));
        //     this.showsizes = true;
        //     this.showsizes1 = false;

        // } 
         if (searchKey.length === 0 && this.pickval === "CATALOUGE PRODUCT") {
            this.products = this.catalogueProducts
            this.showsizes = true;
            this.showsizes1 = false;
        }
        else if (this.pickval === 'CATALOUGE PRODUCT') {
            this.products = this.catalogueProducts.filter(product =>
                product.Name.toLowerCase().includes(searchKey)
            );
            this.showCatalogueButton = true;
            this.showsizes = true;
            this.showsizes1 = false;
        }
        else if (this.pickval === 'CATALOUGE PRODUCT' && searchKey === null) {

            this.showCatalogueButton = true;
            this.products = this.catalogueProducts;
            this.showsizes = true;
            this.showsizes1 = false;
        } else if (this.pickval === 'BLANKS PRODUCT') {
            this.products = this.catalogueProducts.filter(product =>
                product.Name.toLowerCase().includes(searchKey)

            );
            this.selectingProducts = true;
            this.showsizes1 = false;
            this.showsizes = false;
        } else if (this.pickval === 'BLANKS PRODUCT' && searchKey === null) {
            this.products = this.catalogueProducts;
            this.products = this.catalogueProducts;
            this.showsizes = false;
        }
    }

    @track varirnts = [];
    @track groupedVariants = [];


    openModal(event) {
        console.log('OUTPUT : ', 'clicked Model open');
        const productId = event.target.dataset.id;
        const filteredproducts = this.products.find(item => item.Id === productId);
        const variants = filteredproducts.varients;
        this.varirnts = variants != null ? variants : [];

        this.groupVariantsByColor();

        const productImageUrl = event.target.dataset.imageurl;
        const productName = event.target.dataset.name;
        const productPrice = event.target.dataset.price;
        const productPriceEntryId = event.target.dataset.priceentryid;
        const productBoxes = event.currentTarget.dataset.boxes;

        this.selectedProduct = {
            id: productId,
            imageUrl: productImageUrl,
            name: productName,
            price: productPrice,
            priceEntryId: productPriceEntryId,
            boxes: productBoxes
        };

        let variant = {
            productId: productId,
            productName: productName,
            imageUrl: productImageUrl,
            price: productPrice,
            priceEntryId: productPriceEntryId !== null ? productPriceEntryId : null,
            boxes: productBoxes !== null ? productBoxes : 0,
            type: 'Blank'
        };

        this.rows.push(variant);

        this.ismodalopen = true;
    }


    groupVariantsByColor() {
        const grouped = {};
        this.varirnts.forEach(item => {
            if (!grouped[item.Color__c]) {
                grouped[item.Color__c] = [];
            }
            grouped[item.Color__c].push({
                size: item.Size__c,
                id: item.Id,
                productTemplateId: item.Product_Template__c
            });
        });
        this.groupedVariants = Object.keys(grouped).map(color => ({
            color: color,
            sizes: grouped[color]
        }));
    }

    closeModal() {
        this.ismodalopen = false;
        this.rows = [];
    }

    goBackToProductList() {
        this.isVariantView = false;
        this.selectedVariants = [];
        this.selectedProduct = null;
        this.ViewOnProductvarient = false;
    }

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
        const product = this.products.find(i => i.Id === productId);

        this.sizes[productId][size][varId] = quantity;
        
        let totalQuantity =0
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
        qty.quantity = newQuantity;
    }
    checkConditions() {
        if (this.threshholdAmount === 0 || this.totalResidualAmount === 0) {
            return true;
        }
        else if (this.threshholdAmount >= this.totalResidualAmount) {
            return true;
        } else if (this.getDueDate() < this.getDatePlus15Days()) {
            return true
        }
        return false
    }
    catalougeproductSelected(event) {

        if (this.checkConditions() === true) {
            const productId = event.currentTarget.dataset.id;
            const qty = event.target.dataset.qty
            const productName = event.currentTarget.dataset.name;
            const productPrice = event.currentTarget.dataset.price;
            const productImageUrl = event.currentTarget.dataset.imageurl;
            const productBoxes = event.currentTarget.dataset.boxes;
            const quantity = qty !== null ? qty : 0;
            let totalaty = event.target.dataset.total;
            console.log('==============totalaty======================');
            console.log(totalaty);
            console.log('====================================');
            const productVariant = event.currentTarget.dataset.variant;
            const pricebookEntryId = event.currentTarget.dataset.priceentryid;
            const selectedSizes = this.sizes[productId] || {};
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
                type: 'Catalogue'

            };
            let total = 0
            let boxQty = productBoxes != null ? parseInt(productBoxes) : 0;
            console.log('==============boxQty======================');
            console.log(boxQty);
            console.log('====================================');
            Object.keys(selectedSizes).forEach(size => {
                const variants = selectedSizes[size];
                Object.keys(variants).forEach(varId => {
                    const quantityForVariant = parseInt(variants[varId], 10);
                    if (quantityForVariant > 0) {
                        variant.sizes[size][varId] = { quantity: quantityForVariant, color: '' };
                        variant.quantity = Number(quantity)
                        variant.total = parseFloat(totalaty)
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
                if (variant.total === boxQty) {
                    insertCarts({ cartData: variant, recordId: this.userId }).then(result => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Added!',
                                message: 'Item has been added successfully to cart.',
                                variant: 'success',
                            })
                        );
                        this.selectedProductsVarient.push(result)
                    
                    }).catch(error => {
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error!',
                                message: 'Something went wrong. Please try again.', error,
                                variant: 'error',
                            })
                        );
                        console.log('================error====================');
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

    handleDeleteSelectedInParent(event) {
        if (this.selectedProductsVarient.length > 0) {
            const selectedId = event.detail.selected;

            deleteFromCart({ cartId: selectedId, recordId: this.userId }).then(result => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Item has been removed from cart.',
                        variant: 'success',
                    })
                )
               // this.selectedProductsVarient = this.selectedProductsVarient.filter(item => item.id !== selectedId)
            }).catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Something went wrong',
                        variant: 'error',
                    })
                )
            })
        } else {
            this.cart = false
            this.template.querySelector('.main').style.display = 'block'
        }
    }

    showCatalogueButton() {
        this.showCatalogueButton = false;
        this.removeCatalogueButton = true;
    }
    catalougeproductRemoved() {
        this.showCatalogueButton = true;
        this.removeCatalogueButton = false;
    }

    handleCartClick() {
        if (this.selectedProductsVarient.length > 0) {
            console.log('Sending data to child************************8:', JSON.stringify(this.selectedProductsVarient));
            this.cart = true;
            this.products = [];
            this.template.querySelector('.main').style.display = 'none'
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
        this.cart = false;
        this.template.querySelector('.main').style.display = 'block'
        this.products = this.catalogueProducts != null ? this.catalogueProducts : this.AllProducts;
    }
}