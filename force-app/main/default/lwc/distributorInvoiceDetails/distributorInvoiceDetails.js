import { LightningElement, wire } from 'lwc';
import getInvoicesForLoggedInUser from '@salesforce/apex/InvoiceControllerForPortal.getInvoicesForLoggedInUser';

export default class DistributorInvoiceDetails extends LightningElement {
    invoices = [];  
    error;          

   
    @wire(getInvoicesForLoggedInUser)
    wiredInvoices({ error, data }) {
        if (data) {
            this.invoices = data;
            this.invoices=this.invoices.map(invoice => ({
                ...invoice,
                loginurl: 'https://technosport.odoo.com/en/web/login'
            })); 
            this.error = undefined; 
        } else if (error) {
            
            this.error = error.body ? error.body.message : 'Unknown error occurred'; 
            this.invoices = [];  
        }
    }
get invoiceCount() {
        return this.invoices.length;
    }
    
    columns = [
        { label: 'Invoice Name', fieldName: 'Name' },
        { label: 'Residual Amount', fieldName: 'Residual_Amount__c', type: 'currency',cellAttributes: {
                alignment: 'left',
                class: 'residual-amount-red'
                 
            } },
            {label: 'View Details',type:"url",fieldName:'loginurl',target:'_blank'}
    ];

    // Inside your JS file
// columns = [
//     {
//         label: 'Invoice Name',
//         fieldName: 'invoiceName',
//         type: 'text',
//         cellAttributes: {
//             class: 'invoice-name-column'
//         }
//     },
//     {
//         label: 'Residual Amount',
//         fieldName: 'residualAmount',
//         type: 'currency',
//         cellAttributes: {
//             class: 'residual-amount-column'
//         }
//     },
//     // Add other columns as needed
// ];

}