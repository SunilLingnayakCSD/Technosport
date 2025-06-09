import { LightningElement, track, wire } from 'lwc';
import fetchOrders from '@salesforce/apex/OrderController.fetchOrders';
import draftIcon from '@salesforce/resourceUrl/Draft';
import salesOrderIcon from '@salesforce/resourceUrl/SalesOrder';
import invoiceIcon from '@salesforce/resourceUrl/Invoice';

export default class OrderTracking extends LightningElement {
    @track orders = [];
    @track actualResults = [];

    statusIcons = {
        'Draft': draftIcon,
        'Sales Order': salesOrderIcon,
        'Invoice': invoiceIcon
    };

    @wire(fetchOrders)
    wiredOrders({ error, data }) {
        if (data) {
            this.orders = data.map(order => ({
                ...order,
                formattedStatus: this.formatStatusForDisplay(order.status),
                statusPath: this.generateStatusPath(order.status) // Generate status path
            }));
        } else if (error) {
            console.error('Error fetching orders:', error);
        }
    }

    // Generate status path with color
    generateStatusPath(status) {
        const statuses = ['Draft', 'Sales Order', 'Invoice'];
       // let currentStatusIndex = statuses.indexOf(status); 
     const isDraftOrActivated = status === 'Draft' || status === 'Activated';

       let currentStatusIndex = statuses.indexOf(isDraftOrActivated ? 'Draft' : status); // Assign 'Draft' for both 'Draft' and 'Activated'
   return statuses.map((s, index) => ({
            name: s,
            icon: this.statusIcons[s]|| this.statusIcons['Draft'],
            isActive: index === currentStatusIndex, 
            statusColor: index === currentStatusIndex ? 'background-color:blue' : 'background-color:none' // Set color based on active status
        }));
    }


    formatStatusForDisplay(status) {
        if (status === 'Activated') {
            return 'Draft';  // Always display 'Draft' for 'Activated' status
        }
        return status;  // Otherwise, return the status as is
    }
}