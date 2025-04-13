import { LightningElement, track, wire } from 'lwc';
import fetchAllQuotes from '@salesforce/apex/quotationTrackerController.fetchAllQuotes';
//import fetchQuotes from '@salesforce/apex/QuoteController.fetchQuotes';
import draftIcon from '@salesforce/resourceUrl/Draft';
import salesOrderIcon from '@salesforce/resourceUrl/SalesOrder';
import invoiceIcon from '@salesforce/resourceUrl/Invoice';

export default class QuotationFilter extends LightningElement {
    @track startDate = '';
    @track endDate = '';
    @track draftQuotes = [];
    @track salesQuotes = [];
    @track invoiceQuotes = [];
    @track noQuotesFound = false;
    @track quotes = [];
    @track hasData = false;
    @track selectedProductFilter = 'Catalogue';  // Default filter option
    draftIcon = draftIcon;
    salesOrderIcon = salesOrderIcon;
    invoiceIcon = invoiceIcon;

// Options for the product filter combobox
    productFilterOptions = [
       
        { label: 'Blank Products', value: 'Blank' },
        { label: 'Catalogue Products', value: 'Catalogue' }
    ];
    handleProductFilterChange(event){
        this.selectedProductFilter = event.target.value;
    }
    // Handles change in start date
    handleStartDateChange(event) {
        this.startDate = event.target.value;
        console.log('Start Date Changed:', this.startDate);
    }

    // Handles change in end date
    handleEndDateChange(event) {
        this.endDate = event.target.value;
        console.log('End Date Changed:', this.endDate);
    }


    // Fetch the quotes when the button is clicked
    handleFetchQuotes() {
        if (this.startDate && this.endDate) {
            // Clear the quotes arrays before fetching new quotes
            this.draftQuotes = [];
            this.salesQuotes = [];
            this.invoiceQuotes = [];
            this.noQuotesFound = false;
            this.hasData = false;

            console.log('Fetching Quotes for Date Range:', this.startDate, 'to', this.endDate);
            console.log('Using Product Filter:', this.selectedProductFilter);
            fetchAllQuotes({ startDate: this.startDate, endDate: this.endDate,productFilter: this.selectedProductFilter })
                .then(result => {
                      
                    console.log('Fetched Quotes:', result);

                    result.forEach(quote => {
                        console.log('Checking quote:', quote.quoteName, 'Created Date:', quote.createdDate);

                        // Convert the createdDate to JS Date and compare it with start and end date
                        let createdDate = new Date(quote.createdDate);
                        let start = new Date(this.startDate);
                        let end = new Date(this.endDate);

                        if (createdDate >= start && createdDate <= end) {
                            console.log('Quote in date range:', quote.quoteName);

                            // Check if quoteLineItems is a Proxy and convert it into an array
                            let lineItemsArray = Array.isArray(quote.quoteLineItems)
                                ? quote.quoteLineItems
                                : Object.values(quote.quoteLineItems); // Convert Proxy to Array if needed

                            console.log('Quote Line Items (converted):', lineItemsArray);

                            // Segregate quotes based on status
                            switch (quote.status) {
                                case 'Draft':
                                    this.draftQuotes.push(quote);
                                    break;
                                case 'SalesOrder':
                                    this.salesQuotes.push(quote);
                                    break;
                                case 'Invoice':
                                    this.invoiceQuotes.push(quote);
                                    break;
                            }
                        }
                    });


                    //  if (this.draftQuotes.length > 0 || this.salesQuotes.length > 0 || this.invoiceQuotes.length > 0) {
                    //     this.hasData = true;
                    //      console.log('value for quotes found.');
                    // }
                    
                    // If no quotes are found for any status, set noQuotesFound to true
                    // if (!this.hasData) {
                    //     this.noQuotesFound = true;
                    //     console.log('No quotes found.');
                    // }
                })
                .catch(error => {
                    console.error('Error fetching quotes:', error);
                });
        }
    }
}