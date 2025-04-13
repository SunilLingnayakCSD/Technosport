import { LightningElement, wire, track } from 'lwc';
import getDistributorAccounts from '@salesforce/apex/DistributorController.getDistributorAccounts';
import updateSalesTarget from '@salesforce/apex/DistributorController.updateSalesTarget';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DistributorComponent extends LightningElement {
    @track distributors = [];  // To store distributor account data
    selectedDistributorId = ''; // To store the selected distributor account ID
    salesTarget = ''; // To store the sales target value for update
    isLoading = false;

    // Wire the Apex method to get distributor accounts
    @wire(getDistributorAccounts)
    wiredDistributors({ error, data }) {
        if (data) {
            this.distributors = data;
        } else if (error) {
            this.showToast('Error', 'Error fetching distributors', 'error');
        }
    }

    // Handle distributor selection
    handleDistributorChange(event) {
        this.selectedDistributorId = event.detail.value;
        const selectedDistributor = this.distributors.find(
            dist => dist.Id === this.selectedDistributorId
        );
        if (selectedDistributor) {
            this.salesTarget = selectedDistributor.Sales_Target__c || ''; // Set sales target value
        }
    }

    // Handle sales target input change
    handleSalesTargetChange(event) {
        this.salesTarget = event.target.value;
    }

    // Handle save button click to update the sales target
    handleSave() {
        if (this.selectedDistributorId && this.salesTarget !== '') {
            this.isLoading = true;
            updateSalesTarget({ accountId: this.selectedDistributorId, newSalesTarget: parseFloat(this.salesTarget) })
                .then(() => {
                    this.showToast('Success', 'Sales target updated successfully', 'success');
                })
                .catch(error => {
                    this.showToast('Error', 'Error updating sales target', 'error');
                })
                .finally(() => {
                    this.isLoading = false;
                });
        } else {
            this.showToast('Error', 'Please select a distributor and set a sales target value', 'error');
        }
    }

    // Utility method to show toast notifications
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    // Get distributor options for combobox
    get distributorsOptions() {
        return this.distributors.map(dist => ({
            label: dist.Name,
            value: dist.Id
        }));
    }
}