import { LightningElement, wire,track  } from 'lwc';
import getFrequentlyOrderedProducts from '@salesforce/apex/ProductOrderController.getFrequentlyOrderedProducts';

export default class FrequentlyOrderedProducts extends LightningElement {
    @ track orderedProducts = [];
    error;

    @wire(getFrequentlyOrderedProducts)
    wiredProducts({ error, data }) {
        if (data) {
            // console.log('Product Image URL:', data[0].productImageUrl);
            this.orderedProducts = data;
            console.log('this.orderedProducts'+ JSON.stringify(this.orderedProducts,null,2));
        } else if (error) {
            this.error = error;
             console.log('this.error '+this.error );
        }
    }

    handleAddClick(event) {
    // Logic to add the product to cart or handle any other action
    console.log('Product added to cart:', event.target);
   
    const productId = event.target.dataset.id; // Get the product ID
    const product = this.frequentlyOrderedProducts.find(p => p.Id === productId); // Find the product in the list

    // Dispatch event to send this product to the parent component (Cart)
    const addProductEvent = new CustomEvent('addproducttocart', {
        detail: product,
        bubbles: true,
        composed: true
    });
    this.dispatchEvent(addProductEvent);

}

}