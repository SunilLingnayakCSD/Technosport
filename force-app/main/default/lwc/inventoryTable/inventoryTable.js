import { LightningElement, wire } from 'lwc';
import getInventoryData from '@salesforce/apex/InventoryController.getInventoryData';

const COLUMNS = [
    { label: 'Product', fieldName: 'Product__c', sortable: true },
    { label: 'Free Quantity', fieldName: 'Free_Quantity__c', sortable: true },
    { label: 'Available Quantity', fieldName: 'Available_Quantity__c', sortable: true },
    { label: 'Avg Cost', fieldName: 'Avg_Cost__c', sortable: true }
];

export default class InventoryTable extends LightningElement {
    columns = COLUMNS;
    inventoryData = [];
    error;
    sortedDirection = 'asc'; // Default sorting direction
    sortedBy = 'Product__c'; // Default sorting field

    @wire(getInventoryData)
    wiredInventory({ data, error }) {
        if (data) {
            this.inventoryData = data;
            this.error = undefined;
        } else if (error) {
            console.error('Error fetching inventory data:', error);
            this.error = error;
            this.inventoryData = undefined;
        }
    }

    // Handle sort action
    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortedDirection = sortDirection;
        this.sortedBy = sortedBy;

        // Sort the data based on the field and direction
        this.sortData(sortedBy, sortDirection);
    }

    // Function to sort data
    sortData(fieldName, direction) {
        // Copy the data to avoid mutating the original data array
        const parsedData = [...this.inventoryData];

        // Sort the data based on field name and direction
        parsedData.sort((a, b) => {
            let valueA = a[fieldName];
            let valueB = b[fieldName];

            // Handle numeric and string sorting differently
            if (typeof valueA === 'number' && typeof valueB === 'number') {
                return direction === 'asc' ? valueA - valueB : valueB - valueA;
            } else {
                return direction === 'asc'
                    ? valueA > valueB
                        ? 1
                        : valueA < valueB
                        ? -1
                        : 0
                    : valueB > valueA
                    ? 1
                    : valueB < valueA
                    ? -1
                    : 0;
            }
        });

        // Update the inventoryData to trigger re-rendering
        this.inventoryData = parsedData;
    }
}