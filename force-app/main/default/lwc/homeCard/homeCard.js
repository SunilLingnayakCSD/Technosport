import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import products from '@salesforce/resourceUrl/products';
import Place_order from '@salesforce/resourceUrl/Place_order';
import Overview from '@salesforce/resourceUrl/Overview';
import Newlaunches from '@salesforce/resourceUrl/Newlaunches';
import Invoices from '@salesforce/resourceUrl/Invoices';
import customers from '@salesforce/resourceUrl/customers';
import support from '@salesforce/resourceUrl/support';
import lead from '@salesforce/resourceUrl/lead';


export default class HomeCard extends NavigationMixin(LightningElement)  {

    products=products
    Place_order=Place_order
    Overview=Overview
    Newlaunches=Newlaunches
    Invoices=Invoices
    customers=	customers
    support=support
    lead=lead

    handleOverview() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/overview' // Use the URL path for the page
            }
        });
    }

    handleNewLaunches() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/new-launches' // Use the URL path for the page
            }
        });
    }

    handleOrder() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/place-order' // Use the URL path for the page
            }
        });
    }

    handleInvoices() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Invoice__c', // Replace with your object API name
                actionName: 'list' // This navigates to the object's home page
            }
        });
    }

    handleInventory() {
        this[NavigationMixin.Navigate]({
         type: 'standard__webPage',
             attributes: {
                url: '/inventory-tracking' // Use the URL path for the page
            }
        });
    }

    handleOrderTracking() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
             attributes: {
                url: '/order-tracking' // Use the URL path for the page
            }
        });
    }

    handleSupport() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Case', // Replace with your object API name
                actionName: 'list' // This navigates to the object's home page
            }
        });
    }
    handleLead(){
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Lead__c', // Replace with your object API name
                actionName: 'list' // This navigates to the object's home page
            }
        });
    }
   
}