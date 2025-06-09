import { api, LightningElement, track } from 'lwc';
import getAssignedDistributor from '@salesforce/apex/ProductController.getAssignedDistributor';
import getAccounts from '@salesforce/apex/SaveAttachmentController.getAccounts';
import getLastVisitDate from '@salesforce/apex/SaveAttachmentController.getLastVisitDate';
import createOrderRecord from '@salesforce/apex/SaveAttachmentController.createOrderRecord'; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Id from '@salesforce/user/Id'; // Current user's ID

export default class MblPlaceOrderFromHome extends LightningElement {
    
    @api recordId;
    @track userId = Id;
    @track DistributorOptions = [];
    @track selectedDistributorId = '';
    @track selectedDistributorName = '';
    @track AccountOptions = [];
    @track selectedRetailerId = '';
    @track selectedRetailerName = '';
    @track lastVisitDate = null;
    @track orderValue = '';
    @track orderTypeValue = '';
    @track uploadedFileName = '';
    @track selectedRetailerPhone = '';
    @track showDistributor = false;
    @track allRetailers = [];
    @track fileBase64 = '';
    @track isLoading = false;
    @track order = '';
    @track fileUploadKey = Date.now(); 
@track selectedOrderTypes = '';


    @track OrderTypeOptions = [
        { label: 'TD Order', value: 'TD Order' },
        { label: 'Call Order', value: 'Call Order' },
        { label: 'Lead Gen Order', value: 'Lead Gen Order' },
        { label: 'Regular Order', value: 'Regular Order' }
    ];

    connectedCallback() {
        this.getAssignedDistributor();
        this.getAccounts();
    }

    getAssignedDistributor() {
        getAssignedDistributor({ recordId: this.userId ,retailerId: this.selectedRetailerId })
            .then(result => {
                this.DistributorOptions = result.map(item => ({
                    label: item.Distributor_Account__r.Name,
                    value: item.Distributor_Account__c,
                }));
                // Pre-select the distributor if only one is returned
            if (result.length === 1) {
                this.selectedDistributorId = result[0].Distributor_Account__c;
                this.selectedDistributorName = result[0].Distributor_Account__r.Name;
            }
            })
            .catch(error => this.showToast('Error', error.body?.message || error.message, 'error'));
    }

    getAccounts() {
        getAccounts()
            .then(result => {
                this.AccountOptions = result.map(item => ({
                    label: item.Name,
                    value: item.Id,
                    phone: item.Phone,
                    distributorId: item.Distributor__c,
                    distributorName: item.Distributor__r?.Name
                    
                }));
                this.allRetailers = result;
            })
            .catch(error => this.showToast('Error', error.body?.message || error.message, 'error'));
    }

  @track lastvisitId;
    handleretailerChange(event) {
        this.selectedRetailerId = event.target.value;
    
        const selectedRetailer = this.AccountOptions.find(
            option => option.value === this.selectedRetailerId
        );
    
        if (selectedRetailer) {
            this.selectedRetailerName = selectedRetailer.label;
            this.selectedRetailerPhone = selectedRetailer.phone;
    
            if (selectedRetailer.distributorId) {
             
                this.selectedDistributorId = selectedRetailer.distributorId;
    
                const matchedDistributor = this.DistributorOptions.find(
                    dist => dist.value === selectedRetailer.distributorId
                );
    
                if (matchedDistributor) {
                    this.selectedDistributorName = matchedDistributor.label;
                } else {
                    this.selectedDistributorName = ''; 
                }
    
            } else {
                
                this.selectedDistributorId = '';
                this.selectedDistributorName = '';
            }
        }
    
        
        getLastVisitDate({ accountId: this.selectedRetailerId })
            .then(result => {
                this.lastVisitDate = result.cgcloud__Completed_Date__c;
                this.lastvisitId=result.Id;
            })
            .catch(error => {
                this.lastVisitDate = null;
                console.error('Error fetching last visit date:', error);
            });
    }
    
    
    handleDistributorChange(event) {
        this.selectedDistributorId = event.detail.value;

    const selected = this.DistributorOptions.find(
        option => option.value === this.selectedDistributorId
    );

    if (selected) {
        this.selectedDistributorName = selected.label; 
        console.log('Selected Distributor Name:', this.selectedDistributorName);
    }
    }
    

   handleFileUpload(event) {
    const file = event.target.files[0];
    if (file) {
        this.uploadedFileName = file.name;
        const reader = new FileReader();

        reader.onload = () => {
            let base64 = reader.result.split(',')[1];

            // Clean base64 string to avoid issues from Android
            base64 = base64.replace(/\s/g, '').replace(/[\r\n]+/g, '');

            this.fileBase64 = base64;
        };

        reader.readAsDataURL(file);
    }
}


    handleOrderChange(event) {
        this.orderValue = event.target.value;
    }
    handleOrderTypeChange(event) {
        this.orderTypeValue = event.target.value;
    }

   async handleSubmit() {
    if (!this.selectedDistributorId || !this.selectedDistributorName || !this.selectedRetailerName || !this.selectedRetailerId || !this.orderValue || !this.lastVisitDate || !this.orderTypeValue || !this.uploadedFileName ) {
        this.showToast('Missing Fields', 'Please fill all fields before submitting.', 'warning');
        return;
    }

    this.isLoading = true; // Show spinner

    try {
        const result = await createOrderRecord({
            distributorId: this.selectedDistributorId,
            distributorName: this.selectedDistributorName,
            retailerId: this.selectedRetailerId,
            retailerName: this.selectedRetailerName,
            lastvisitDate: this.lastVisitDate,
            visitId: this.lastvisitId,
            orderValue: this.orderValue,
            orderTypeValue:this.orderTypeValue,
            base64Image: this.fileBase64,
            fileName: this.uploadedFileName
        });

        console.log('result:', result);

        // Reset form fields
        this.selectedDistributorId = '';
        this.selectedDistributorName = '';
        this.selectedRetailerId = '';
        this.selectedRetailerName = '';
        this.lastVisitDate = '';
        this.orderValue = '';
        this.fileBase64 = '';
        this.uploadedFileName = '';
        this.orderTypeValue = '';
        this.selectedRetailerPhone = '';


        // Reset the lookup field manually
        const lookup = this.template.querySelector('.look');
        if (lookup) {
            lookup.value = '';
        }

        this.fileUploadKey = Date.now();

        this.showToast('Success', 'Order created successfully!', 'success');
    } catch (error) {
        this.showToast('Error', error.body?.message || error.message, 'error');
    } finally {
        this.isLoading = false; // Hide spinner
    }
}


    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    

    
}