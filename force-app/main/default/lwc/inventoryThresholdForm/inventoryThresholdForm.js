import { LightningElement, track } from 'lwc';
import saveInventoryThresholds from '@salesforce/apex/InventoryThresholdController.saveInventoryThresholds';
import getInventoryRecords from '@salesforce/apex/InventoryThresholdController.getInventoryRecords';
import getPicklistValues from '@salesforce/apex/InventoryThresholdController.getPicklistValues'; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class InventoryThresholdForm extends LightningElement {
    @track highQuantityThresholdMin;
    @track highQuantityThresholdMax;
    @track mediumQuantityThresholdMin;
    @track mediumQuantityThresholdMax;
    @track lowQuantityThresholdMin;
    @track lowQuantityThresholdMax;
    @track productCategory;
    @track productCategory1;
    @track productCategoryOptions = [];
    @track productCategory1Options = [];
    @track showThresholdFields = false;
    @track categoryError;
    @track categoryError1;
    @track fieldErrors = {
        highQuantityThresholdMin: '',
        highQuantityThresholdMax: '',
        mediumQuantityThresholdMin: '',
        mediumQuantityThresholdMax: '',
        lowQuantityThresholdMin: '',
        lowQuantityThresholdMax: ''
    };

    // Fetch picklist values when the component loads
    connectedCallback() {
        this.fetchPicklistValues();
    }

    // Fetch picklist values from Apex
    fetchPicklistValues() {
        getPicklistValues()
            .then((result) => {
                if (result) {
                    this.productCategoryOptions = result.Product_Category__c;
                    this.productCategory1Options = result.Product_Category1__c;
                }
            })
            .catch((error) => {
                console.error('Error fetching picklist values:', error);
            });
    }

    // Handle change in Product Category selection
    handleProductCategory(event) {
        this.productCategory = event.target.value;
        this.categoryError = undefined;
        this.checkCategories();
    }

    // Handle change in Product Category1 selection
    handleProductCategory1(event) {
        this.productCategory1 = event.target.value;
        this.categoryError1 = undefined;
        this.checkCategories();
    }

    // Check if both categories are selected
    // checkCategories() {
    //     if (this.productCategory && this.productCategory1) {
    //         this.fetchInventoryRecords();
    //     } else {
    //         this.showThresholdFields = false;
    //     }
    // }

    checkCategories() {
    if (this.productCategory && this.productCategory1) {
        this.fetchInventoryRecords();
    } else {
        this.showThresholdFields = false;
        this.categoryError = undefined;  // Clear previous error when categories are not selected
        this.categoryError1 = undefined;  // Clear categoryError1 when categories are not selected
    }
}


    // Fetch inventory records based on selected categories
    // fetchInventoryRecords() {
    //     getInventoryRecords({ productCategory: this.productCategory, productCategory1: this.productCategory1 })
    //         .then(result => {
    //             if (result.length > 0) {
    //                 const inventory = result[0];
    //                 this.highQuantityThresholdMin = inventory.High_Quantity_Threshold_Min__c;
    //                 this.highQuantityThresholdMax = inventory.High_Quantity_Threshold_Max__c;
    //                 this.mediumQuantityThresholdMin = inventory.Medium_Quantity_Threshold_Min__c;
    //                 this.mediumQuantityThresholdMax = inventory.Medium_Quantity_Threshold_Max__c;
    //                 this.lowQuantityThresholdMin = inventory.Low_Quantity_Threshold_Min__c;
    //                 this.lowQuantityThresholdMax = inventory.Low_Quantity_Threshold_Max__c;
    //                 this.showThresholdFields = true;
    //             } else {
    //                 this.categoryError = 'No inventory records found for the selected categories.';
    //                 this.showThresholdFields = false;
    //             }
    //         })
    //         .catch(error => {
    //             console.error('Error fetching inventory records:', error);
    //             this.categoryError = 'Error fetching inventory records.';
    //             this.showThresholdFields = false;
    //         });
    // }

    fetchInventoryRecords() {
    getInventoryRecords({ productCategory: this.productCategory, productCategory1: this.productCategory1 })
        .then(result => {
            if (result.length > 0) {
                const inventory = result[0];
                this.highQuantityThresholdMin = inventory.High_Quantity_Threshold_Min__c;
                this.highQuantityThresholdMax = inventory.High_Quantity_Threshold_Max__c;
                this.mediumQuantityThresholdMin = inventory.Medium_Quantity_Threshold_Min__c;
                this.mediumQuantityThresholdMax = inventory.Medium_Quantity_Threshold_Max__c;
                this.lowQuantityThresholdMin = inventory.Low_Quantity_Threshold_Min__c;
                this.lowQuantityThresholdMax = inventory.Low_Quantity_Threshold_Max__c;
                this.showThresholdFields = true;
                this.categoryError = undefined; // Clear previous category error
            } else {
                this.categoryError = 'No inventory records found for the selected Section';
                this.categoryError1 = 'No inventory records found for the selected categories'
                this.showThresholdFields = false;
                
                // Show a toast message for "No records found"
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'No inventory records found for the selected Options.',
                        variant: 'error',
                    })
                );
            }
        })
        .catch(error => {
            console.error('Error fetching inventory records:', error);
            this.categoryError = 'Error fetching inventory records.';
            this.showThresholdFields = false;
            
            // Show a toast message for the error fetching records
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'An error occurred while fetching inventory records.',
                    variant: 'error',
                })
            );
        });
}

    // Handlers for input field changes
    handlehighQuantityThresholdMin(event) {
        this.highQuantityThresholdMin = event.target.value;
        this.validateFields();
    }

    handlehighQuantityThresholdMax(event) {
        this.highQuantityThresholdMax = event.target.value;
        this.validateFields();
    }

    handlemediumQuantityThresholdMin(event) {
        this.mediumQuantityThresholdMin = event.target.value;
        this.validateFields();
    }

    handlemediumQuantityThresholdMax(event) {
        this.mediumQuantityThresholdMax = event.target.value;
        this.validateFields();
    }

    handlelowQuantityThresholdMin(event) {
        this.lowQuantityThresholdMin = event.target.value;
        this.validateFields();
    }

    handlelowQuantityThresholdMax(event) {
        this.lowQuantityThresholdMax = event.target.value;
        this.validateFields();
    }

    // Validate input values
    validateFields() {
        let isValid = true;
        this.fieldErrors = {};

        // High Quantity Threshold Validation
        if (!this.highQuantityThresholdMin) {
            this.fieldErrors.highQuantityThresholdMin = 'High Quantity Min is required.';
            isValid = false;
        } else if (this.highQuantityThresholdMin < 0) {
            this.fieldErrors.highQuantityThresholdMin = 'Negative values are not allowed.';
            isValid = false;
        } else if (parseFloat(this.highQuantityThresholdMin) > parseFloat(this.highQuantityThresholdMax)) {
            this.fieldErrors.highQuantityThresholdMin = 'High Quantity Min must be less than or equal to High Quantity Max.';
            isValid = false;
        }

        if (!this.highQuantityThresholdMax) {
            this.fieldErrors.highQuantityThresholdMax = 'High Quantity Max is required.';
            isValid = false;
        } else if (this.highQuantityThresholdMax < 0) {
            this.fieldErrors.highQuantityThresholdMax = 'Negative values are not allowed.';
            isValid = false;
        }

        // Medium Quantity Threshold Validation
        if (!this.mediumQuantityThresholdMin) {
            this.fieldErrors.mediumQuantityThresholdMin = 'Medium Quantity Min is required.';
            isValid = false;
        } else if (this.mediumQuantityThresholdMin < 0) {
            this.fieldErrors.mediumQuantityThresholdMin = 'Negative values are not allowed.';
            isValid = false;
        } else if (parseFloat(this.mediumQuantityThresholdMin) > parseFloat(this.mediumQuantityThresholdMax)) {
            this.fieldErrors.mediumQuantityThresholdMin = 'Medium Quantity Min must be less than or equal to Medium Quantity Max.';
            isValid = false;
        }

        if (!this.mediumQuantityThresholdMax) {
            this.fieldErrors.mediumQuantityThresholdMax = 'Medium Quantity Max is required.';
            isValid = false;
        } else if (this.mediumQuantityThresholdMax < 0) {
            this.fieldErrors.mediumQuantityThresholdMax = 'Negative values are not allowed.';
            isValid = false;
        }

        // Low Quantity Threshold Validation
        if (!this.lowQuantityThresholdMin) {
            this.fieldErrors.lowQuantityThresholdMin = 'Low Quantity Min is required.';
            isValid = false;
        } else if (this.lowQuantityThresholdMin < 0) {
            this.fieldErrors.lowQuantityThresholdMin = 'Negative values are not allowed.';
            isValid = false;
        } else if (parseFloat(this.lowQuantityThresholdMin) > parseFloat(this.lowQuantityThresholdMax)) {
            this.fieldErrors.lowQuantityThresholdMin = 'Low Quantity Min must be less than or equal to Low Quantity Max.';
            isValid = false;
        }

        if (!this.lowQuantityThresholdMax) {
            this.fieldErrors.lowQuantityThresholdMax = 'Low Quantity Max is required.';
            isValid = false;
        } else if (this.lowQuantityThresholdMax < 0) {
            this.fieldErrors.lowQuantityThresholdMax = 'Negative values are not allowed.';
            isValid = false;
        }

        return isValid;
    }

    // Save the updated thresholds
    handleSave() {
        if (!this.productCategory || !this.productCategory1) {
            this.categoryError = 'Please select both product categories.';
            return;
        }

        if (!this.validateFields()) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please fix the errors and try again.',
                    variant: 'error',
                })
            );
            return;
        }

        // Call Apex to save the updated thresholds
        saveInventoryThresholds({
            productCategory: this.productCategory,
            productCategory1: this.productCategory1,
            highQuantityThresholdMin: this.highQuantityThresholdMin,
            highQuantityThresholdMax: this.highQuantityThresholdMax,
            mediumQuantityThresholdMin: this.mediumQuantityThresholdMin,
            mediumQuantityThresholdMax: this.mediumQuantityThresholdMax,
            lowQuantityThresholdMin: this.lowQuantityThresholdMin,
            lowQuantityThresholdMax: this.lowQuantityThresholdMax
        })
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Inventory thresholds updated successfully!',
                    variant: 'success',
                })
            );
        })
        .catch((error) => {
            console.error('Error saving inventory thresholds', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'An error occurred while saving inventory thresholds.',
                    variant: 'error',
                })
            );
        });
    }
}