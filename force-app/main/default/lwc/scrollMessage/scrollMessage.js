import { LightningElement, track } from 'lwc';
import updateScrollMessage from '@salesforce/apex/SaveScrollMessageController.updateScrollMessage';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ScrollMessagePortal extends LightningElement {
    // Default message
    @track message = '';

    // Handle input field change
    handleMessageChange(event) {
        this.message = event.target.value || 'Welcome to Technosport! Explore the latest in premium sportswear and performance gear...';
         console.log('Message Saved:',   this.message);
    }

    saveMessage() {
        updateScrollMessage({ message: this.message })
            .then(result => {
                console.log('Message Saved:', result);
                this.showToast('Success', result, 'success');
            })
            .catch(error => {
                console.error('Error saving message:', error);
                this.showToast('Error', error.body.message, 'error');
            });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}