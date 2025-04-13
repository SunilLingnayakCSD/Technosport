// import { LightningElement, api, wire } from 'lwc';
// import getProductDetails from '@salesforce/apex/ToDisplayProduct.getProductDetails';

// export default class ProductDetails extends LightningElement {
//     @api recordId; 
//     productName; 
//     imageUrl; 
//     productCategory; 
//     productState; 
//     productStatus;
//     @wire(getProductDetails, { recordId: '$recordId' })
//     wiredProduct({ error, data }) {
//         if (data) {
//             console.error('data', data);
            
//             this.productName = data.Name;
//             this.imageUrl = data.Image_URL__c;
//             this.productCategory = data.Product_Category__c;
//             this.productState = data.Product_Type__c;
//             this.productStatus = data.cgcloud__State__c;
//         } else if (error) {
//             console.error('Error loading product data', error);
//         }
//     }
// }


//Image_URL__c, Product_Category__c, Product_Type__c, cgcloud__State__c



// import { LightningElement, wire, api, track } from 'lwc';
// import getProduct from '@salesforce/apex/ToDisplayProduct.getProduct';

// export default class ToDisplayProductImage extends LightningElement {
//     @api recordId;
//     @track products = null; 

//     connectedCallback() {
//         console.log('Record ID:', this.recordId);
//     }

//     @wire(getProduct, { recordId: '$recordId' })
//     wiredProduct({ data, error }) {
//         if (data && data.length > 0) {
//             this.products = data[0]; 
//             console.log('Fetched Product:', this.products);
//         } else if (error) {
//             console.error('Error fetching product:', error);
//         }
//     }
// }



//import { LightningElement, wire, api, track } from 'lwc';
// import getProductWithImage from '@salesforce/apex/ToDisplayProduct.getProductWithImage';
//import product from '@salesforce/apex/ProductImage.product';

// export default class ToDisplayProductImage extends LightningElement {
//     @api recordId; 
//     @track products = null; 
//     @track isLoading = true; 
    
//     @wire(product, { recordId: '$recordId' })
//     wiredProduct({ data, error }) {
//         console.log(JSON.stringify(data))
//         if (data) {
//             this.products = data;
//             this.isLoading = false; 
//             console.log('Fetched Product:', this.products);
//         } else if (error) {
//             this.isLoading = false; 
//             console.error('Error fetching product:', error);
//         }
//     }
//       get imageUrl() {
//         return this.products?.Image_URL__c; 
//        }
     
//     connectedCallback() {
//         console.log('Record ID:', this.recordId);
//     }
// }



import { LightningElement, wire, api, track } from 'lwc';
import product from '@salesforce/apex/ProductImage.product';

export default class ToDisplayProductImage extends LightningElement {
    @api recordId; 
    @track products = null; 
    @track isLoading = true; 
    @track imageurl = '';
    @track oneProduct = null;
    @track stateName = ''; 

  
    @wire(product, { recordId: '$recordId' })
    wiredProduct({ data, error }) {
        console.log(JSON.stringify(data))
        if (data) {
            this.products = data;
            console.log('data==> : ',JSON.stringify(data));
            this.imageurl= this.products[0].URL__c;
            console.log('imageurl : ',this.imageurl);
            this.oneProduct=this.products[0];
          if (this.oneProduct.IsActive) {
                this.stateName = 'Active'; 
                //this.stateName = 'Inactive'; 
            }
            this.isLoading = false; 
            console.log('Fetched Product:', this.products);
        } else if (error) {
            this.isLoading = false; 
            console.error('Error fetching product:', error);
        }
    }

    get imageUrl() {
        return this.imageurl;
    }

    connectedCallback() {
        console.log('Record ID:', this.recordId);
    }
}