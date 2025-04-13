// import { LightningElement, wire } from 'lwc';
// import scrollMessage from '@salesforce/apex/SaveScrollMessageController.scrollMessage';
// import { NavigationMixin } from 'lightning/navigation';

// export default class ScrollingMessage extends NavigationMixin(LightningElement) {
//     scrollingMessage;

//     @wire(scrollMessage)
//     wiredScrollMessage({ error, data }) {
//         if (data) {
//             // If data is available, set the scrolling message
//             this.scrollingMessage = data.length > 0 ? data[0] : 'Default scrolling message';
//         } else if (error) {
//             // If there's an error, log it and set a default error message
//             console.error('Error fetching scroll message:', error);
//             this.scrollingMessage = 'Error loading message';
//         }
//     }

//     handleOverview() {
//         // Navigation to overview page when triggered
//         this[NavigationMixin.Navigate]({
//             type: 'standard__webPage',
//             attributes: {
//                 url: '//buy-plan-and-future-visibility' // Use the URL path for the page
//             }
//         });
//     }
// }

import { LightningElement, wire,track } from 'lwc';
import getScrollMessage from '@salesforce/apex/SaveScrollMessageController.getScrollMessage';
import { NavigationMixin } from 'lightning/navigation';

export default class ScrollingMessage extends NavigationMixin(LightningElement) {
    @track scrollingMessage;

    @wire(getScrollMessage, { message: 'New Scroll Message' }) // You can pass a message here if needed
    wiredScrollMessage({ error, data }) {
        if (data) {
            console.log('OUTPUT : ',data);
            // If data is available, set the scrolling message
            this.scrollingMessage = data; // It is a string, not an array
            console.log('OUTPUT : ',this.scrollingMessage);
        } else if (error) {
            // If there's an error, log it and set a default error message
            console.error('Error fetching scroll message:', error);
            this.scrollingMessage = 'Error loading message';
        }
    }

    handleOverview() {
        // Navigation to overview page when triggered
        this[NavigationMixin.Navigate]( {
            type: 'standard__webPage',
            attributes: {
                url: '/buy-plan-and-future-visibility' // Use the relative URL path for the page
            }
        });
    }
}