import { LightningElement, api, track,wire } from 'lwc';
import getContact from '@salesforce/apex/ContactDetailPage.getContact'
// import Profile from '@salesforce/resourceUrl/Profile';
export default class ContactDetailPage extends LightningElement {
    @api contactId;
    @api recordId;
    @track contactInfo;
    contactInfo=true;
    error;
    // connectedCallback() {
    //     console.log('Component Initialized with Contact ID:', this.contactId);
    //     console.log('Record ID:', this.recordId);
    // }
@wire(getContact, { contactId: '$recordId' })
wiredContact({ error, data }) {
    console.log('contactId:', this.contactId, 'recordId:', this.recordId); // Check if the contactId is valid
    if (data) {
        console.log('Data from Apex:', data); // Log data from Apex
        this.contactInfo = data;
        this.error = undefined;
    } else if (error) {
        console.error('Error from Apex:', error); // Log error details
        this.error = error;
        this.contactInfo = undefined;
    }
}

    get accountname() {
        return this.contactInfo?.Account?.Name || '';
    }

     

    //  get pic() {
    //     return Profile; 
    // }
}