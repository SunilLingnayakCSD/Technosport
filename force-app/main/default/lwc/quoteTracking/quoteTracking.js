import { LightningElement, track, wire } from 'lwc';
import getOrderSummaryData from '@salesforce/apex/QuoteController.getOrderSummaryData';

export default class OrderTracking extends LightningElement {



 @track processedOrders = [];
 @track orderDetails = false;
 @track startDate = '';
 @track endDate = '';

handleStartDateChange(event) {
    this.startDate = event.target.value;
    console.log('Start Date Changed:', this.startDate);
}

handleEndDateChange(event) {
    this.endDate = event.target.value;
    console.log('End Date Changed:', this.endDate);
}

handleFetchOrders(){
    this.orderDetails = true;

     if (!this.startDate || !this.endDate) {
        console.error('Start or End Date is missing.');
        return;
    }

    getOrderSummaryData({ 
        startDate: this.startDate, 
        endDate: this.endDate 
    })
    .then((data) => {
        console.log('Fetched Data:', JSON.stringify(data));
        this.processedOrders = this.transformData(data);
        console.log('Processed Orders:', this.processedOrders);
    })
    .catch((error) => {
        console.error('Error fetching order data:', error);
    });

}



    transformData(data) {
        let transformed = [];
    console.log('====================================');
    console.log(JSON.stringify(data,null,2));
    console.log('====================================');
        data.forEach((order, index) => {
            const rowSpan = order.orderItems?.length || 1;
    
            if (order.orderItems && order.orderItems.length > 0) {
                order.orderItems.forEach((item, itemIndex) => {
                    transformed.push({
                        key: `${order.orderId}-${itemIndex}`,
                        formattedDate: this.formatDate(order.orderDate),
                        productName: item.productName || '—',
                        receivedRatio: item.description || '_',
                        receivedBundles: order.quoteCount || 0,
                        reservedCount: order.reservedCount || 0,
                        sizes:order.sizes,
                        dispatchBundles: order.invoiceCount || 0,
                      //  holdCount: order.onHoldCount || 0,
                        cancelledCount: order.cancelledCount || 0,
						quoteDescription: order.orderDescription || '',
                                quoteRatio:order.Ratio,
                        isFirstRow: itemIndex === 0,
                        rowSpan: rowSpan
                    });
                });
            } else {
                transformed.push({
                    key: order.orderId || `order-${index}`,
                    formattedDate: this.formatDate(order.orderDate),
                    productName: '—',
                    receivedRatio: '_',
                    receivedBundles: order.quoteCount || 0,
                    reservedCount: order.reservedCount || 0,
                    dispatchBundles: order.invoiceCount || 0,
                    sizes:order.sizes,
                    holdCount: order.onHoldCount || 0,
                    cancelledCount: order.cancelledCount || 0,
					quoteDescription: order.orderDescription || '',
                                quoteRatio:order.Ratio,
                    isFirstRow: true,
                    rowSpan: 1
                });
            }
        });
    
        return transformed;
    }
    
    

    formatDate(dateString) {
        if (!dateString) return '—';
        const date = new Date(dateString);
        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const year = String(date.getFullYear()).slice(-2);
        return `${day}.${month}.${year}`;
    }
}