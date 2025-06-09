import { LightningElement, api, track } from 'lwc';
import generateVisitPdf from '@salesforce/apex/VisitPdfAttachment.generateVisitPdf';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OrderPDF extends LightningElement {
    @api recordId;
    @track isLoading = true;
    @track isSuccess = false;
    @track errorMsg;

    connectedCallback() {
        this.generatePdfAndSave();
    }

  generatePdfAndSave() {
    generateVisitPdf({ visitId: this.recordId })
        .then((result) => {
            if (result === true) {
                this.isSuccess = true;
                this.showToast('Success', 'PDF generated and attached successfully.', 'success');
            } else {
                // result is false, no Order found
                this.errorMsg = 'Order is not created for this visit';
            }
        })
        .catch(error => {
            const message = error?.body?.message || error?.message || 'Unexpected error';
            this.errorMsg = message;
            this.showToast('Error', this.errorMsg, 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });
}

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}