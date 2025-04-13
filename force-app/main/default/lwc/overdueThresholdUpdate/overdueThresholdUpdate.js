import { LightningElement } from 'lwc';
import updateAllAccountsThreshold from '@salesforce/apex/accountOverdueThresholdController.updateAllAccountsThreshold';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OverdueThresholdUpdate extends LightningElement {
    overdueThreshold;

    handleInputChange(event) {
        // Capture input value and log it to the console for debugging
        this.overdueThreshold = event.target.value;
        console.log('Input changed. New overdueThreshold value:', this.overdueThreshold);
    }

    handleSave() {
        // Check if the overdueThreshold is a valid number
        if (this.overdueThreshold !== undefined && this.overdueThreshold !== '') {
            // Ensure that the value is a valid number
            if (isNaN(this.overdueThreshold)) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Overdue Threshold must be a valid number.',
                        variant: 'error',
                    })
                );
                return;
            }

            // Log the value of overdueThreshold to the console before calling Apex
            console.log('Overdue Threshold value before calling Apex:', this.overdueThreshold);

            // Call Apex method to update all accounts
            updateAllAccountsThreshold({ overdueThreshold: parseFloat(this.overdueThreshold) })
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Overdue Threshold updated successfully for all accounts.',
                            variant: 'success',
                        })
                    );
                })
                .catch((error) => {
                    // Log the error to the console for debugging
                    console.error('Error in updating overdue threshold:', error);

                    // Show an error toast with the error message
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error updating Overdue Threshold',
                            message: error.body.message,
                            variant: 'error',
                        })
                    );
                });
        } else {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please enter a valid value for Overdue Threshold.',
                    variant: 'error',
                })
            );
        }
    }
}