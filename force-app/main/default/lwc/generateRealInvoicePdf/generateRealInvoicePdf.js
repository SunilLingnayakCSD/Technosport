import { LightningElement, api,track } from 'lwc';
import generateReceiptEstimatePdf from '@salesforce/apex/ReceiptPdfAttachment1.generateReceiptEstimatePdf';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
export default class GenerateRealInvoicePdf extends NavigationMixin(LightningElement) {


    @api recordId;
    @track baseurl;
    connectedCallback() {
        console.log('OUTPUT : ', this.recordId);
    }
    get vfPageUrl() {
        // return `/distributor/apex/Invoice2?id=${this.recordId}`;
        this.baseurl = window.location.origin;
        console.log('base url-------> : ', window.location.origin);
        if (this.baseurl.includes("site")) {
            return `${window.location.origin}/distributor/apex/Invoice2?id=${this.recordId}`;
        } else {
            return `${window.location.origin}/apex/Invoice2?id=${this.recordId}`;
        }

    }

    handleSavetoAttchment() {
        console.log('input : ', this.recordId);
        generateReceiptEstimatePdf({ input: this.recordId })
            .then(result => {
                console.log('PDF downloaded successfully:', result);
                this.showSuccessToast('PDF downloaded successfully!');
                this.closeModal();
            }).catch(error => {
                this.showErrorToast('PDF Download Failed!');
            });
    }

    // handleSaveandEmail(){
    // generateReceiptEstimatePdf({input : this.recordId})
    //  .then(result=>{
    //     console.log('PDF downloaded successfully:', result);
    //     //this.showSuccessToast('PDF downloaded and Sent Email successfully!');
    //    this.callemailclass();
    //     //this.closeModal();
    //  }).catch(error=>{
    //    this.showErrorToast('PDF Download Failed!');
    //  });    

    // }

    // callemailclass(){
    //  emailReceiptPdf({input : this.recordId})
    //  .then(result=>{
    //     console.log('Sent Email successfully:', result);
    //     this.showSuccessToast('PDF downloaded and Sent Email successfully!');
    //     this.closeModal();
    //  }).catch(error=>{
    //   this.showErrorToast('Email Not Sent!, Check Contact');
    //  });
    // }

    showSuccessToast(message) {
        const event = new ShowToastEvent({
            title: 'Success',
            message: message,
            variant: 'success',
        });
        this.dispatchEvent(event);
    }

    showErrorToast(message) {
        const event = new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    closeModal() {
        console.log('Navigating away...');
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId,
                actionName: 'view',
            },
        });
    }
}