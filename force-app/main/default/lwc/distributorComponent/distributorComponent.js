import { LightningElement, wire, track } from 'lwc';
import getDistributorAccounts from '@salesforce/apex/DistributorController.getDistributorAccounts';
import updateOverdueThreshold from '@salesforce/apex/DistributorController.updateOverdueThreshold';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DistributorComponent extends LightningElement {
    @track distributors = [];  // To store distributor account data
    selectedDistributorId = ''; // To store the selected distributor account ID
    overdueThreshold = ''; // To store the overdue threshold value for update
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
            this.overdueThreshold = selectedDistributor.Overdue_Threshold_Limit__c || '';
        }
    }

    // Handle overdue threshold input change
    handleThresholdChange(event) {
        this.overdueThreshold = event.target.value;
    }

    // Handle save button click to update the overdue threshold limit
    handleSave() {
        if (this.selectedDistributorId && this.overdueThreshold !== '') {
            this.isLoading = true;
            updateOverdueThreshold({ accountId: this.selectedDistributorId, newLimit: parseFloat(this.overdueThreshold) })
                .then(() => {
                    this.showToast('Success', 'Overdue threshold updated successfully', 'success');
                })
                .catch(error => {
                    this.showToast('Error', 'Error updating overdue threshold', 'error');
                })
                .finally(() => {
                    this.isLoading = false;
                });
        } else {
            this.showToast('Error', 'Please select a distributor and set a threshold value', 'error');
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