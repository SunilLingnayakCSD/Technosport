import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import autoGenerateAndAttach from '@salesforce/apex/VisitPdfAttachment.autoGenerateAndAttach';

export default class VisitPdfQuickAction extends LightningElement {
    @api recordId;

    connectedCallback() {
        if (!this.recordId) {
            this.showToast('Error', 'No Visit Id received', 'error');
            return;
        }

        autoGenerateAndAttach({ recordId: this.recordId })
            .then(() => {
                this.showToast('Success', 'PDF generated and attached.', 'success');
                this.close();
                this.refresh();
            })
            .catch(err => {
                this.showToast('Error', err?.body?.message || err.message, 'error');
                this.close();
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    close() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    refresh() {
        eval("$A.get('e.force:refreshView').fire();");
    }
}