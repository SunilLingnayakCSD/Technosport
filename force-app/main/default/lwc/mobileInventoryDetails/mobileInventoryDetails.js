import { LightningElement, wire, track } from 'lwc';
import getInventoryRecords from '@salesforce/apex/InventoryController.getInventoryRecords';
import getSearchRecords from '@salesforce/apex/InventoryController.getSearchRecords';
import getPicklistValues from '@salesforce/apex/InventoryController.getPicklistValues';

export default class MobileInventoryDetails extends LightningElement {
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

    connectedCallback() {
        this.loadPicklistValues();
    }

    loadPicklistValues() {
        this.isLoading = true;
        
        Promise.all([
            getPicklistValues({
                objectName: 'Inventory__c',
                fieldName: 'Product_Category__c'
            }),
            getPicklistValues({
                objectName: 'Inventory__c',
                fieldName: 'Product_Category1__c'
            }),
            getPicklistValues({
                objectName: 'Inventory__c',
                fieldName: 'Stock_Status__c'
            })
        ])
        .then(([category, category1, status]) => {
            this.productCategoryOptions = category;
            this.productCategory1Options = category1;
            this.stockStatusOptions = status;
            this.isLoading = false;
        })
        .catch(error => {
            this.error = error;
            this.isLoading = false;
            console.error('Error loading picklist values:', error);
        });
    }

    // Wire method to load initial data
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
        this.searchInventoryRecords();
   
}

    // Handler for product category dropdown
    handleProductCategoryChange(event) {
        this.productCategory = event.detail.value;
        this.searchInventoryRecords();
    }

    // Handler for product category1 dropdown
    handleProductCategory1Change(event) {
        this.productCategory1 = event.detail.value;
        this.searchInventoryRecords();
    }

    // Handler for stock status dropdown
    handleStockStatusChange(event) {
        this.stockStatus = event.detail.value;
        this.searchInventoryRecords();
    }

    // Main search method that works with all filters
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

    // Method to clear all filters
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

    // Method to determine the stock level color based on Inventory_Stock_Status__c
    getStockLevelStyle(record) {
        if (record.Inventory_Stock_Status__c) {
            if (record.Inventory_Stock_Status__c.includes('High')) {
                return `background-color: green;`; // Green for High stock
            } else if (record.Inventory_Stock_Status__c.includes('Medium')) {
                return `background-color: orange;`; // Orange for Medium stock
            } else if (record.Inventory_Stock_Status__c.includes('Low')) {
                return `background-color: red;`; // Red for Low stock
            }
        }
        return null; // Default no style
    }
}