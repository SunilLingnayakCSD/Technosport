import { LightningElement, wire } from 'lwc';
import getInvoicesForLoggedInUser from '@salesforce/apex/InvoiceControllerForPortal.getInvoicesForLoggedInUser';

export default class DistributorInvoiceDetails extends LightningElement {
    ledgers = [];  
    error;          

   
    @wire(getInvoicesForLoggedInUser)
    wiredInvoices({ error, data }) {
        if (data) {
            this.ledgers = data;
            this.error = undefined; 
        } else if (error) {
            
            this.error = error.body ? error.body.message : 'Unknown error occurred'; 
            this.ledgers = [];  
        }
    }
get invoiceCount() {
        return this.ledgers.length;
    }
    
    columns = [
        { label: 'Ledger Name', fieldName: 'Name' },
        { label: 'Credit', fieldName: 'Credit__c', type: 'currency'
            // ,cellAttributes: {
            //     alignment: 'left',
            //     class: 'residual-amount-red'
                 
            // } 
        },
            {label: 'Debit',type:"currency",fieldName:'Debit__c'},
            {label: 'Balance',type:"currency",fieldName:'Balance__c'}
           
    ];

    

}