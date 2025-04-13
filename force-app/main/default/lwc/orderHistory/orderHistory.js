import { LightningElement, wire } from 'lwc';
import getMostFrequentOrders from '@salesforce/apex/OrderTrackingController.getMostFrequentOrders';
import getProductNames from '@salesforce/apex/OrderTrackingController.getProductNames';

export default class OrderHistory extends LightningElement {
    orders = [];  // To store the list of most frequent orders
    error;        // To store any errors
    productMap = {}; // Map to store product names by Product2Id

    // Wire the Apex method to get the most frequent orders
    @wire(getMostFrequentOrders)
    wiredOrders({ error, data }) {
        if (data) {
            // Extract Product2Ids from the aggregate results
            const productIds = [...new Set(data.map(order => order.Product2Id))]; // Get unique Product2Ids
            
            // Fetch product names from the Product2 records only once
            getProductNames({ productIds })
                .then(productData => {
                    // Map product names by Product2Id
                    this.productMap = productData.reduce((acc, product) => {
                        acc[product.Id] = product.Name;
                        return acc;
                    }, {});

                    // Now, map the orders and assign product names
                    this.orders = data.map(order => ({
                        productName: this.productMap[order.Product2Id] || 'Unnamed Product',
                        totalQuantity: order.totalQuantity,
                    }));
                })
                .catch(error => {
                    this.error = error.body.message || 'Error fetching product names';
                    console.log('Error fetching product names:', JSON.stringify(error));
                });
        } else if (error) {
            // Handle the error and display the message
            this.error = error.body.message || 'Unknown error occurred';
            console.log('Error occurred:', JSON.stringify(error));
        }
    }
}