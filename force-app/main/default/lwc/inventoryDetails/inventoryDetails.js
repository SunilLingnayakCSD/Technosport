import { LightningElement, wire, track } from 'lwc';
import getInventoryRecords from '@salesforce/apex/InventoryController.getInventoryRecords';
import getSearchRecords from '@salesforce/apex/InventoryController.getSearchRecords';

import INV_OBJ from '@salesforce/schema/Inventory__c';
import Product_Category1__c from '@salesforce/schema/Inventory__c.Product_Category1__c';
import Product_Category__c from '@salesforce/schema/Inventory__c.Product_Category__c';
import Stock_Status__c from '@salesforce/schema/Inventory__c.Stock_Status__c'

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';

export default class InventoryDetails extends LightningElement {
    @track records = [];
    @track error;
    @track searchTerm = '';
    @track productCategory = '';
    @track productCategory1 = '';
    @track stockStatus = '';
    @track productCategoryOptions = [];
    @track productCategory1Options = [];
    @track stockStatusOptions = [];
    @track isLoading = false;

 @wire(getObjectInfo, { objectApiName: INV_OBJ })
    invInfo;

    @wire(getPicklistValues, {
        recordTypeId: '$invInfo.data.defaultRecordTypeId',
        fieldApiName: Product_Category__c
    })
    getProductSection({ error, data }) {
        if (data) {
            this.productCategoryOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));
        } else {
            console.error('Error fetching Product_Category__c picklist', error);
        }
    }
    @wire(getPicklistValues, {
            recordTypeId: '$invInfo.data.defaultRecordTypeId',
            fieldApiName:Stock_Status__c})
            getstockSection({ error, data }) {
                if (data) {
                    this.stockStatusOptions = data.values.map(item => ({
                        label: item.label,
                        value: item.value
                    }));
                } else {
                    console.error('Error fetching Product_Category__c picklist', error);
                }
            }    

    dependentRawData;
    controllerValuesMap;

    @wire(getPicklistValues, {
        recordTypeId: '$invInfo.data.defaultRecordTypeId',
        fieldApiName: Product_Category1__c
    })

    getProductCategory({ error, data }) {
        if (data) {
            console.log('=================data===================');
            console.log(JSON.stringify(data));
            console.log('====================================');
            this.dependentRawData = data.values;
            this.controllerValuesMap = data.controllerValues;
           

        } else {
            console.error('Error fetching Product_Type__c picklist', error);
        }
    }
    
    @wire(getInventoryRecords)
    wiredRecords({ error, data }) {
        if (data) {
            this.records = data.map(record => ({
                ...record,
                stockLevelStyle: this.getStockLevelStyle(record)
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.records = [];
        }
    }

 handleSearchChange(event) {
    this.searchTerm = event.target.value;   
    clearTimeout(this.delayTimeout);
    this.delayTimeout = setTimeout(() => {
        this.searchInventoryRecords();
    }, 300);
}
    handleProductCategoryChange(event) {
        this.productCategory = event.detail.value;
        const controllerKey = this.controllerValuesMap[this.productCategory];
        this.productCategory1Options = this.dependentRawData.filter(item =>
            item.validFor.includes(controllerKey)
        ).map(item => ({
            label: item.label,
            value: item.value
        }));
        this.searchInventoryRecords();
    }

    handleProductCategory1Change(event) {
        this.productCategory1 = event.detail.value;
        this.searchInventoryRecords();
    }

    handleStockStatusChange(event) {
        this.stockStatus = event.detail.value;
        this.searchInventoryRecords();
    }

    searchInventoryRecords() {
        getSearchRecords({
            searchTerm: this.searchTerm,
            productCategory: this.productCategory,
            productCategory1: this.productCategory1,
            stockStatus: this.stockStatus
        })
        .then(result => {
            this.records = result.map(record => ({
                ...record,
                stockLevelStyle: this.getStockLevelStyle(record)
            }));
            this.error = undefined;
        })
        .catch(error => {
            this.error = error;
            this.records = [];
            console.error('Error fetching records:', error);
        });
    }

  clearFilters() {
        this.searchTerm = '';
        this.productCategory = '';
        this.productCategory1 = '';
        this.stockStatus = '';
        
        this.template.querySelectorAll('lightning-combobox').forEach(combobox => {
            combobox.value = '';
        });
        
        this.template.querySelector('lightning-input').value = '';
        
        this.searchInventoryRecords();
    }

    getStockLevelStyle(record) {
        if (record.Inventory_Stock_Status__c) {
            if (record.Inventory_Stock_Status__c.includes('High')) {
                return `background-color: green;`;
            } else if (record.Inventory_Stock_Status__c.includes('Medium')) {
                return `background-color: orange;`; 
            } else if (record.Inventory_Stock_Status__c.includes('Low')) {
                return `background-color: red;`; 
            }
        }
        return null; 
    }
}