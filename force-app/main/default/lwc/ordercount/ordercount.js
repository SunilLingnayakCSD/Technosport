import { LightningElement, wire, track } from 'lwc';
import getOrderDetails from '@salesforce/apex/OrderCountApexClass.getOrderDetails';
import dispatchSelectedCount from '@salesforce/apex/Odoo_dispatch_reservedbundles.dispatchSelectedCount'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
export default class OrderCount extends LightningElement {
    @track orderData = [];

    @track wiredorderResult;

    @track allorderdata = [];


    @wire(getOrderDetails)
    wiredOrders(result) {
        this.wiredorderResult = result
        const { data, error } = result
        if (data) {
            console.log('====================================');
            console.log(JSON.stringify(data, null, 2));
            console.log('====================================');
            this.orderData = data.map(order => {

                return {
                    orderId: order.orderId,
                    orderNumber: order.orderNumber,
                    orderdate: order.orderDate,
                    orderAge: order.orderAge,
                    orderclass: order.orderAge > 30
                        ? 'slds-hint-parent highlightred-background'
                        : order.orderAge > 15
                            ? 'slds-hint-parent highlightyellow-background'
                            : order.orderAge <= 15
                                ? 'slds-hint-parent highlight-background'
                                : 'slds-hint-parent'

                    ,
                    productNamesHtml: (order.orderLineItem && order.orderLineItem.length > 0 &&
                        order.orderLineItem[0].Product2 &&
                        order.orderLineItem[0].Product2.Product_Template__r)
                        ? order.orderLineItem[0].Product2.Product_Template__r.Name
                        : 'N/A',

                    totalQuantity: order.quoteNotInInvoice ? order.quoteNotInInvoice : 0,
                    dispatchCount: null
                    //totalQty: totalQty,
                    //invoiceCount:

                };
            });
            this.allorderdata = this.orderData
            console.log('====================================');
            console.log(JSON.stringify(this.orderData, null, 2));
            console.log('====================================');
        } else if (error) {
            console.error('Error fetching order data from Apex: ', error);
        }
    }

    handleSearch(event) {
        const searchKey = event.target.value.trim().toUpperCase();

        if (searchKey.length === 0) {

            this.orderData = this.allorderdata;
        } else {

            this.orderData = this.allorderdata.filter(order =>
                order.productNamesHtml.toUpperCase().includes(searchKey)
            );
            console.log('====================================');
            console.log(JSON.stringify(this.orderData, null, 2));
            console.log('====================================');
        }
    }

  


    handleInputChange(event) {
        const orderNumber = event.target.dataset.id;
        const value = event.target.value;

        this.orderData = this.orderData.map(order => {
            if (order.orderId === orderNumber) {
                return { ...order, dispatchCount: value };
            }

            return order;
        });
        console.log('===============orderData=====================');
        console.log(JSON.stringify(this.orderData, null, 2));
        console.log('====================================');
    }

    handleDispatch(event) {
        const orderNumber = event.target.dataset.id;

        console.log('====================================');
        console.log(orderNumber);
        console.log('====================================');
        let filterorderdata = this.orderData.find(item => item.orderId === orderNumber)

        const dispatchCount = parseFloat(filterorderdata.dispatchCount);
        const bundle = parseFloat(filterorderdata.totalQuantity);
        console.log('====================================');
        console.log(dispatchCount, '****', orderNumber);
        console.log('====================================');
        if (dispatchCount > 0) {
            if (dispatchCount <= bundle) {
                dispatchSelectedCount({ Count: dispatchCount, OrderId: orderNumber }).then(result => {
                    console.log('====================================');
                    console.log(result);
                    console.log('====================================');

                    const successEvent = new ShowToastEvent({
                        title: 'Dispatched Successfully',
                        message:
                            'Order has been Dispatched Successfully',
                        variant: 'success'
                    });
                    this.dispatchEvent(successEvent);
                    refreshApex(this.wiredorderResult).then(() => {
                        console.log('Component partially refreshed with updated data.');
                    })
                        .catch((error) => {
                            console.error('Error refreshing component:', error);
                        });
                    //window.location.reload()


                }).catch(error => {
                    console.log('====================================');
                    console.log(error);
                    console.log('====================================');
                    const errorEvent = new ShowToastEvent({
                        title: 'Error',
                        message:
                            'Error in Dispatched',
                        variant: 'error'
                    })
                    this.dispatchEvent(errorEvent)
                })

                console.log(`Dispatch clicked for Order Number: ${orderNumber}`);
            }else{
                const errorEvent = new ShowToastEvent({
                    title: 'Error',
                    message:
                        'Dispatch Quantity is More than Reserved Quantity',
                    variant: 'error'
                })
                this.dispatchEvent(errorEvent)
            }
            } else {
                const errorEvent = new ShowToastEvent({
                    title: 'Error',
                    message:
                        'Please Enter Quantity',
                    variant: 'error'
                })
                this.dispatchEvent(errorEvent)
            }
        }
    }