import { LightningElement, track, wire } from 'lwc';
import techno from '@salesforce/resourceUrl/techno';
import BackIcon from '@salesforce/resourceUrl/BackIcon';
import DownArrow from '@salesforce/resourceUrl/DownArrow';
import getProducts from '@salesforce/apex/ProductController.getProducts';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getInvoicesForLoggedInUserdue from '@salesforce/apex/InvoiceControllerForPortal.getInvoicesForLoggedInUserdue';
import getAccountsForLoggedInUser from '@salesforce/apex/ProductController.getAccountsForLoggedInUser'
import Id from '@salesforce/user/Id'
import insertCarts from '@salesforce/apex/CartController.insertCarts'
import getAllCartItems from '@salesforce/apex/CartController.getAllCartItems'
import deleteFromCart from '@salesforce/apex/CartController.deleteFromCart'
import LightningAlert from 'lightning/alert';
import PRODUCT_OBJECT from '@salesforce/schema/Product2';
import Product_Category__c from '@salesforce/schema/Product2.Product_Category__c';
import Product_Type__c from '@salesforce/schema/Product2.Product_Type__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import Is_Blank__c from '@salesforce/schema/User.Is_Blank__c';
import Is_Catalogue_c__c from '@salesforce/schema/User.Is_Catalogue_c__c';
import { getRecord } from 'lightning/uiRecordApi';

export default class DistributorPortal extends LightningElement {
    userId = Id
    scrollingMessage = [];
    @track accountDetails
    @track threshholdAmount;
    @track totalResidualAmount
    @track threshholddays;
    @track isFutureProducts = false;
    days

    @track productSectionOptions = [];
    @track productcategoryOptions = [];
    @track selectedProductSection;
    @track filteredProductCategoryOptions = [];
    @track dependentSelectedval = null


    @track productOptions
    @track isblank
    @track isCatalogue
    @wire(getRecord, { recordId: '$userId', fields: [Is_Blank__c, Is_Catalogue_c__c] })
    getuserdetails({ error, data }) {
        if (data) {

            this.isblank = data.fields.Is_Blank__c.value
            this.isCatalogue = data.fields.Is_Catalogue_c__c.value
            console.log('===========data-------=========================');
            console.log(data);
            console.log('====================================');
            console.log(this.isblank);
            console.log('====================================', this.isCatalogue);
            console.log('====================================');
            let options = [];
            if (data.fields.Is_Catalogue_c__c.value === true && data.fields.Is_Blank__c.value === true) {
                options.push({ label: 'Catalogue Products', value: 'CATALOUGE PRODUCT' }, { label: 'Blank Products', value: 'BLANKS PRODUCT' });

                this.pickval = 'CATALOUGE PRODUCT'
                this.showCatalogueButton = true;
                this.showsizes = true;

                this.selectingProducts = false;
            }
            else if (data.fields.Is_Catalogue_c__c.value === true) {
                options.push({ label: 'Catalogue Products', value: 'CATALOUGE PRODUCT' });
                this.pickval = 'CATALOUGE PRODUCT'
                console.log('=============isCatalogue=======================');
                console.log(this.pickval);
                console.log('====================================');
                this.showCatalogueButton = true;
                this.showsizes = true;

                this.selectingProducts = false;
            }
            else if (data.fields.Is_Blank__c.value === true) {
                options.push({ label: 'Blank Products', value: 'BLANKS PRODUCT' });
                this.pickval = 'BLANKS PRODUCT'
                console.log('=============isBlank=======================');
                console.log(this.pickval);
                console.log('====================================');
                this.showCatalogueButton = false;
                this.selectingProducts = true;

                this.showsizes = false;
            }

            this.productOptions = options;
            this.getProductsBasedOnCondition(this.pickval, this.categoryval, this.isFutureProducts, this.dependentSelectedval)


        } else {
            console.log('====================================');
            console.log(error);
            console.log('====================================');
        }
    }
    @wire(getObjectInfo, { objectApiName: PRODUCT_OBJECT })
    productInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$productInfo.data.defaultRecordTypeId',
        fieldApiName: Product_Category__c
    })
    getProductSection({ error, data }) {
        if (data) {
            this.productSectionOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else {
            console.error('Error fetching Product_Category__c picklist', error);
        }
    }

    dependentRawData;
    controllerValuesMap;

    @wire(getPicklistValues, {
        recordTypeId: '$productInfo.data.defaultRecordTypeId',
        fieldApiName: Product_Type__c
    })

    getProductCategory({ error, data }) {
        if (data) {
            
            this.dependentRawData = data.values;
            this.controllerValuesMap = data.controllerValues;

        } else {
            console.error('Error fetching Product_Type__c picklist', error);
        }
    }

    getAccountsForLoggedInUsermethod() {
        getAccountsForLoggedInUser({ recordId: this.userId }).then(result => {
            this.accountDetails = result
            this.threshholdAmount = this.accountDetails[0].Overdue_Threshold_Limit__c
            this.totalResidualAmount = this.accountDetails[0].Total_Invoice_Amount__c
            this.threshholddays = this.accountDetails[0].Threshold_days__c
            let number = this.threshholddays.match(/\d+/);
            this.dayss = number != null ? number[0] : 0
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
        getInvoicesForLoggedInUserdue()
            .then((data) => {
                if (data && data.length > 0) {
                    this.duedateForLastInvoice = data[0]?.Due_Date__c || null;
                    console.log('==============duedateForLastInvoice======================');
                    console.log(this.duedateForLastInvoice);
                    console.log('====================================');
                    console.log('================this.threshholdAmount ====================');
                    console.log(this.threshholdAmount);
                    console.log('====================================');
                    console.log('=============this.totalResidualAmount=======================');
                    console.log(this.totalResidualAmount);
                    console.log('====================================');
                    if (this.totalResidualAmount >= this.threshholdAmount && this.getDueDate() > this.getDatePlus15Days()) {
                        LightningAlert.open({
                            message: 'Your invoice is overdue. Please make the payment.',
                            theme: 'warning', // Possible values: 'info', 'success', 'error', 'warning'
                            label: 'Overdue Invoice'

                        });
                    }
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
    @track cart = false;
    techno = techno;
    BackIcon = BackIcon;
    DownArrow = DownArrow;
    @track products = [];
    @track isLoading = true;
    @track selectedProductsVarient = [];
    @track sizes = {};
    @track filterType = [];
    @track filteredProducts = [];
    @track pickval;
    @track selectedProduct = null;
    @track categoryval='Men';
    @track showCatalogueButton = true;
    @track removeCatalogueButton = false;
    @track selectedFilter = '';
    @track showsizes = true;
    @track selectingProducts = false;
    @track ismodalopen = false;

    connectedCallback() {

        this.getAccountsForLoggedInUsermethod()
        this.fetchInvoices()
        // this.getdefaultProducts();
        console.log('==============pickval======================');
        console.log(this.pickval);
        console.log('====================================');
        this.getAllcartDetailsFromAccount();
        // if (this.getDueDate() > this.getDatePlus15Days()) {
        //     LightningAlert.open({
        //         message: 'Your invoice is overdue. Please make the payment.',
        //         theme: 'warning',
        //         label: 'Overdue Invoice'
        //     });
        // }

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
                    sizes: item.Cart_Items__r != null ? item.Cart_Items__r.map(size => ({
                        ...size,
                        statusLabel: size.isUpcomingVarient__c ? 'Upcoming' : 'Current'
                    })) : [],
                    isFutureProduct: item.isFutureProduct__c,
                    isFutureQuoShouuldteCreate: item.isFutureQuoShouuldteCreate__c
                }
            })
        })

    }
    @track total;

    handleQuantityAndSize(event) {
        const productId = event.target.dataset.id;
        const size = event.target.dataset.size;
        const key = event.target.dataset.varid;
        const color = event.target.dataset.color;
        const value = parseFloat(event.target.value);

        console.log('=============value=======================');
        console.log(value);
        console.log(JSON.stringify(this.rows, null, 2));
        console.log(productId);
        console.log('====================================');

        const row = this.rows.find(r => r.productId === productId);
        if (!row.sizes) {
            row.sizes = {};
        }

        if (!row.sizes[size]) {
            row.sizes[size] = {};
        }

        row.sizes[size][key] = { quantity: value, color: color, isUpcomingVariant: false };

        let totalQuantity = 0;
        for (const sizeKey in row.sizes) {
            if (row.sizes.hasOwnProperty(sizeKey)) {
                for (const varKey in row.sizes[sizeKey]) {
                    totalQuantity += row.sizes[sizeKey][varKey].quantity || 0;
                }
            }
        }
        row.quantity = totalQuantity;

        this.groupedVariants = this.groupedVariants.map(group => {
            if (group.color === color) {
                let colorTotal = 0;

                group.sizes.forEach(sizeItem => {

                    const matchingRow = this.rows.find(r => r.productId === sizeItem.productTemplateId);
                    const sizeData = matchingRow?.sizes?.[sizeItem.size]?.[sizeItem.id];
                    const val = sizeData?.quantity || 0;

                    sizeItem.quantity = val;
                    colorTotal += val;
                });

                group.totalQuantitycolor = colorTotal;
            }
            return group;
        });

        this.total = this.groupedVariants.reduce((accumulator, item) => {
            return accumulator + item.totalQuantitycolor;
        }, 0);

        console.log('====================this.groupedVariants================');
        console.log(JSON.stringify(this.groupedVariants, null, 2));
        console.log('====================================');
    }

    @track cartlength
    addToCart() {
        console.log('====================================');
        console.log(this.threshholdAmount, '*******', this.totalResidualAmount);
        console.log('====================================');

        
            const sizeInputs = this.template.querySelectorAll('.size-input');
            const selectedItems = [];

            sizeInputs.forEach(input => {
                const quantity = parseInt(input.value, 10) || 0;
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
                    color: item.color,
                    isUpcomingVariant: false
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
                total: calculatedQuantity,
                isFutureProduct: this.selectedProduct.isFutureProduct,
                isFutureQuoShouuldteCreate: this.selectedProduct.isFutureQuoShouuldteCreate
            };
            console.log('====================================');
            console.log(JSON.stringify(cartItem, null, 2));
            console.log('====================================');
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
                        if (parseInt(input.value, 10) > 0) {
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
       
    }

    get background() {
        return `background-image: url(${this.downArrowUrl}); background-repeat: no-repeat; background-position: right center; padding-right: 30px;`;
    }

    renderedCallback() {
        this.initializeAccordion();
    }

    initializeAccordion() {

        const acc = this.template.querySelectorAll('.accordion');
        const nxt = this.template.querySelectorAll('.next');

        if (acc.length > 0) {
            acc.forEach((element) => {

                if (!element.hasAttribute('data-listener')) {
                    element.addEventListener('click', () => this.toggleAccordion(element));

                    element.setAttribute('data-listener', 'true');
                }
            });
        }
        if (nxt.length > 0) {
            nxt.forEach((element) => {
                console.log('called nxt');

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
    rowLimit = 500;
    isDataComplete = false;

    handleScroll(event) {
        // const bottomOfList = event.target.scrollHeight === event.target.scrollTop + event.target.clientHeight;
        let bottomOfList = event.target.scrollHeight - event.target.scrollTop <= event.target.clientHeight + 10;
        if (bottomOfList && !this.isLoading && !this.isDataComplete) {

            this.getProductsBasedOnCondition(this.pickval, this.categoryval, this.isFutureProducts, this.dependentSelectedval)

        }
    }

    async getProductsBasedOnCondition(filterval, categoryval, isfuture, catval) {

        this.isLoading = true;
        console.log('Fetching products for filter:', filterval, 'category:', categoryval, isfuture, catval);

        try {
            const data = await getProducts({
                filterValue: filterval,
                categoryValue: categoryval,
                limitSize: this.rowLimit,
                offset: this.rowOffset,
                isfuture: isfuture,
                catval: catval
            });
            console.log(data.length,'length');
            
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
                    const isFutureProduct = product.isFutureProduct__c;
                    const availabledate = product.Next_Available_Date__c
                    let varients = product.Products1__r && product.Products1__r.length > 0 ? product.Products1__r.filter(item => item.Is_Upcoming_Variant__c === false) : [];

                    let nxtAvailableProducts = Array.isArray(product.Products1__r)
                        ? product.Products1__r.filter(item => item.Is_Upcoming_Variant__c === true)
                        : [];

                        varients = varients
                        .filter(item => {
                            return item.Inventories__r && item.Inventories__r.length > 0 &&
                                   item.Inventories__r[0].Free_Quantity__c > 0;
                        })
                        .map(item => {
                            let invfreeqty = item.Inventories__r[0].Free_Quantity__c >= 50
                                ? 50
                                : item.Inventories__r[0].Free_Quantity__c;
                    
                            return {
                                ...item,
                                freeqty: parseFloat(invfreeqty).toFixed()
                            };
                        });
                    
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
                        noofpieces: product.Number_of_pieces_in_Box__c,
                        isFutureProduct: isFutureProduct,
                        nxtAvailableProducts: nxtAvailableProducts,
                        availabledate: availabledate
                    };
                })];

                this.rowOffset += this.rowLimit;
            }

            this.filteredProducts = [...this.products];
            this.catalogueProducts = this.products;
            this.cart = false;
            this.isLoading = false;
            

        } catch (error) {
            console.error('Error filtering products:', error);
            this.isLoading = false;
        }
    }

    handleCategoryChange(event) {

        event.preventDefault();
        const category = event.target.dataset.category;
        if (category) {
            this.products = [];
            this.rowOffset = 0;
            this.categoryval = category;
            this.dependentSelectedval = null
            const controllerKey = this.controllerValuesMap[category];

            this.filteredProductCategoryOptions = this.dependentRawData.filter(item =>
                item.validFor.includes(controllerKey)
            ).map(item => ({
                label: item.label,
                value: item.value
            }));
            this.getProductsBasedOnCondition(this.pickval, this.categoryval, this.isFutureProducts, this.dependentSelectedval)
        }
    }

    handleDependentPicklist(event) {
        this.products = [];
        this.rowOffset = 0;
        this.dependentSelectedval = event.target.value
        console.log('============this.dependentSelectedval========================');
        console.log(this.dependentSelectedval);
        console.log('====================================');
        this.getProductsBasedOnCondition(this.pickval, this.categoryval, this.isFutureProducts, this.dependentSelectedval)
    }

    handleFilterChange(event) {
        this.selectedFilter = event.target.value;
        console.log('============this.selectedFilter========================');
        console.log(this.selectedFilter);
        console.log('====================================');
        this.products = [];
        this.rowOffset = 0;
        if (this.selectedFilter === 'CATALOUGE PRODUCT') {
            this.showCatalogueButton = true;
            this.showsizes = true;

            this.selectingProducts = false;

        } else if (this.selectedFilter === 'BLANKS PRODUCT') {
            this.showCatalogueButton = false;
            this.selectingProducts = true;

            this.showsizes = false;

        }
        this.pickval = this.selectedFilter
        this.getProductsBasedOnCondition(this.pickval, this.categoryval, this.isFutureProducts, this.dependentSelectedval)
    }
    toggleHamburgerMenu() {
        const categoryLinks = this.template.querySelector('.category-links');
        categoryLinks.classList.toggle('show');
    }

    handleFutureProducts(event) {
        console.log('================event.target.value====================');
        console.log(event.target.value);
        console.log('====================================');
        
        this.rowOffset = 0;  
        this.isDataComplete = false;
        this.products = []; 
        this.filteredProducts = [];
        this.catalogueProducts = [];

        if (event.target.value !== null && event.target.value === 'true') {
            console.log('calling inside Future');
         
            this.isFutureProducts = true
          
            console.log(this.isFutureProducts);
        } if (event.target.value !== null && event.target.value === 'false') {
            console.log('calling inside old');
            console.log(this.isFutureProducts);
            this.isFutureProducts = false

        }
        console.log('====================================');
        console.log(this.pickval);
        console.log(this.categoryval);
        console.log(this.isFutureProducts);
        console.log(this.dependentSelectedval);
        
        console.log('====================================');
        this.getProductsBasedOnCondition(this.pickval, this.categoryval, this.isFutureProducts, this.dependentSelectedval)

    }
    searchProduct(event) {
        const searchKey = event.target.value.toLowerCase();
        if (searchKey.length === 0 && this.pickval === "CATALOUGE PRODUCT") {
            this.products = this.catalogueProducts
            this.showsizes = true;

        }
        else if (this.pickval === 'CATALOUGE PRODUCT') {
            this.products = this.catalogueProducts.filter(product =>
                product.Name.toLowerCase().includes(searchKey)
            );
            this.showCatalogueButton = true;
            this.showsizes = true;

        }
        else if (this.pickval === 'CATALOUGE PRODUCT' && searchKey === null) {

            this.showCatalogueButton = true;
            this.products = this.catalogueProducts;
            this.showsizes = true;

        } else if (this.pickval === 'BLANKS PRODUCT') {
            this.products = this.catalogueProducts.filter(product =>
                product.Name.toLowerCase().includes(searchKey)

            );
            this.selectingProducts = true;
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
        console.log(JSON.stringify(this.varirnts, null, 2))
        const bool = event.target.dataset.bool
        if (bool === 'true') {
            this.ismodalopen = false;

        } else {
            this.ismodalopen = true;

        }
        this.total = 0
        this.groupVariantsByColor();
        console.log('*******', JSON.stringify(this.varirnts, null, 2))

        const productImageUrl = event.target.dataset.imageurl;
        const productName = event.target.dataset.name;
        const productPrice = event.target.dataset.price;
        const productPriceEntryId = event.target.dataset.priceentryid;
        const productBoxes = event.currentTarget.dataset.boxes;
        const isFutureProduct = event.currentTarget.dataset.future
        const totalqty = event.target.dataset.qty
        console.log('============totalqty========================');
        console.log(totalqty);
        console.log('====================================');
        this.selectedProduct = {
            id: productId,
            imageUrl: productImageUrl,
            name: productName,
            price: productPrice,
            priceEntryId: productPriceEntryId,
            boxes: productBoxes,
            quantity: parseFloat(totalqty),
            isFutureProduct: isFutureProduct,
            isFutureQuoShouuldteCreate: false
        };

        console.log('=================selectedProduct===================');
        console.log(JSON.stringify(this.selectedProduct, null, 2));
        console.log('====================================');
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
                productTemplateId: item.Product_Template__c,
                quantity: 0,
                freeqty: item.freeqty
            });
        });
        this.groupedVariants = Object.keys(grouped).map(color => ({
            color: color,
            sizes: grouped[color],
            totalQuantitycolor: 0

        }));
        console.log('==============groupedVariants======================');
        console.log(JSON.stringify(this.groupedVariants, null, 2));
        console.log('====================================');
    }

    closeModal() {
        this.ismodalopen = false;
        this.total = 0
        this.rows = [];
    }



    handleSizeInput(event) {
        const productId = event.target.dataset.id;
        const varId = event.target.dataset.varid;
        const size = event.target.dataset.size;
        const isupcomingvarient = event.target.dataset.isupcomingvarient;
        console.log('==========isupcomingvarient==========================');
        console.log(isupcomingvarient, typeof (isupcomingvarient));
        console.log('====================================');

        const quantity = isNaN(parseFloat(event.target.value)) ? 0 : parseFloat(event.target.value);

        if (!this.sizes[productId]) {
            this.sizes[productId] = {};
        }

        if (!this.sizes[productId][size]) {
            this.sizes[productId][size] = {};
        }
        const product = this.products.find(i => i.Id === productId);

        this.sizes[productId][size][varId] = { quantity: quantity, isUpcomingVariant: isupcomingvarient };
        // this.sizes[productId][size][varId] = isupcomingvarient;
        if (isupcomingvarient === 'false') {
            let totalQuantity = 0
            for (const sizeKey in this.sizes[productId]) {
                if (this.sizes[productId].hasOwnProperty(sizeKey)) {
                    for (const varKey in this.sizes[productId][sizeKey]) {
                        if (this.sizes[productId][sizeKey].hasOwnProperty(varKey)) {
                            const variantData = this.sizes[productId][sizeKey][varKey];
                            // const quavariantQuantityntity = parseFloat(variantData.quantity);
                            // // const variantQuantity = this.sizes[productId][sizeKey][varKey];


                            // if (!isNaN(quavariantQuantityntity)) {
                            //     totalQuantity += quavariantQuantityntity;
                            // }
                            if (variantData.isUpcomingVariant === 'false') {
                                const variantQuantity = parseFloat(variantData.quantity);
                                if (!isNaN(variantQuantity)) {
                                    totalQuantity += variantQuantity;
                                }
                            }
                        }
                    }
                }
            }
            if (product) {
                product.total = totalQuantity;
                console.log('Product with updated total:', product.total);
                console.log(JSON.stringify(product, null, 2));

            } else {
                console.error('Product not found');
            }
            console.log(JSON.stringify(this.sizes, null, 2));


        }




    }




    handleQuantityInput(event) {
        const productId = event.target.dataset.id
        const qty = this.products.find(item => item.Id === productId)
        const newQuantity = event.target.value;
        qty.quantity = newQuantity;
    }
    
    catalougeproductSelected(event) {


            const productId = event.currentTarget.dataset.id;
            const qty = event.target.dataset.qty
            const productName = event.currentTarget.dataset.name;
            const productPrice = event.currentTarget.dataset.price;
            const productImageUrl = event.currentTarget.dataset.imageurl;
            const productBoxes = event.currentTarget.dataset.boxes;
            const quantity = qty !== null ? qty : 0;
            let totalaty = event.target.dataset.total;
            console.log('==============totalaty===isFutureProduct===================', productBoxes);
            console.log(totalaty);
            console.log('=================isFutureProduct===================');
         
            
            const productVariant = event.currentTarget.dataset.variant;
            const pricebookEntryId = event.currentTarget.dataset.priceentryid;
            const isFutureProduct = event.target.dataset.isfuture
            const selectedSizes = this.sizes[productId] || {};
            console.log(isFutureProduct);
            console.log(typeof(isFutureProduct));
            
            let variant = {
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
                isFutureProduct: isFutureProduct,
                isFutureQuoShouuldteCreate: false

            };
            let total = 0
            let boxQty = productBoxes != null ? parseInt(productBoxes) : 0;
            console.log('==============boxQty======================');
            console.log(boxQty);
            console.log('====================================');
            // variant.isFutureQuoShouuldteCreate = Object.values(selectedSizes).some(variants =>
            //     Object.values(variants).some(v => v.isUpcomingVariant === true)
            // );
            Object.keys(selectedSizes).forEach(size => {
                const variants = selectedSizes[size];
                Object.keys(variants).forEach(varId => {
                    const variantData = variants[varId];
                    let quantityForVariant = parseInt(variantData.quantity, 10);
                    let isUpcomingVariant = variantData.isUpcomingVariant;
                    console.log('=================88888888888888888===================');
                    console.log(isUpcomingVariant);
                    console.log('===================variantData.isUpcomingVariant=================');
                    console.log(variantData.isUpcomingVariant, typeof (variantData.isUpcomingVariant));

                    if (variantData.isUpcomingVariant == 'true') {
                        console.log('====================================');
                        console.log('hiiiiiiiiiiiiii');
                        console.log('====================================');
                        variant.isFutureQuoShouuldteCreate = Boolean(variantData.isUpcomingVariant)
                    }
                    if (quantityForVariant > 0) {
                        variant.sizes[size][varId] = {
                            quantity: quantityForVariant,
                            color: '',
                            isUpcomingVariant: isUpcomingVariant

                        };
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
                console.log(typeof (variant.total));
                if(isFutureProduct==='false'){
                if (variant.total === boxQty) {
                    console.log('================variant====================');
                    console.log(JSON.stringify(variant, null, 2));
                    console.log('====================================');
                    this.handleinsertCarts(variant,this.userId);
                } else {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error!',
                            message: 'Total Item Quantity is should be equals to Box quantity.',
                            variant: 'error',
                        })
                    );
                }
            }else{
                this.handleinsertCarts(variant,this.userId);
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

        

    }
    handleinsertCarts(variant,userId){
        insertCarts({ cartData: variant, recordId: userId }).then(result => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Added!',
                    message: 'Item has been added successfully to cart.',
                    variant: 'success',
                })
            );
            let recivedres = result != null ? result.sizes.map(size => ({
                ...size,
                statusLabel: size.isUpcomingVarient__c ? 'Upcoming' : 'Current'
            })) : []
            result.sizes = recivedres;
            this.selectedProductsVarient.push(result)
            console.log("8888", JSON.stringify(this.selectedProductsVarient, null, 2));

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
            }).catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Something went wrong',
                        variant: 'error',
                    })

                )
                console.log('====================================');
                console.log(error);
                console.log('====================================');
            })
        } else {
            this.cart = false
            this.template.querySelector('.main').style.display = 'block'
        }
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
    // hidden
    toggleVariants(event) {
        const productId = event.currentTarget.dataset.target;
        const variantRows = this.template.querySelectorAll(`tr[data-variants="${productId}"]`);
        const arrow = event.currentTarget.querySelector('.arrow');

        variantRows.forEach(row => {
            row.style.display = row.style.display === 'none' ? 'table-row' : 'none';
        });

        // Rotate arrow animation
        arrow.style.transform = arrow.style.transform === 'rotate(180deg)'
            ? 'rotate(0deg)'
            : 'rotate(180deg)';
    }
}