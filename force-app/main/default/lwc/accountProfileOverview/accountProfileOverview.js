import { LightningElement, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import USER_ID from '@salesforce/user/Id';  // Get logged-in user ID
import getInvoices from '@salesforce/apex/UserProfileController.getInvoices';  // Apex method to get invoices
import getQuotations from '@salesforce/apex/UserProfileController.getQuotations';  // Apex method to get quotations

import USER_NAME_FIELD from '@salesforce/schema/User.Name';  // User Name field
//import USER_PHOTO_FIELD from '@salesforce/schema/User.FullPhotoUrl';  // User Photo URL field

export default class AccountProfileOverview extends LightningElement {
    userName = '';
    userPhotoUrl = '';
    userEmail = '';
    userPhone = '';
    activeTab = 'address'; // Default active tab is 'address'
    invoices = [];
    quotations = [];

    // Fetch the logged-in user's record
    @wire(getRecord, {
        recordId: USER_ID,
        fields: [USER_NAME_FIELD, USER_PHOTO_FIELD]
    })
    user({ data, error }) {
        if (data) {
            this.userName = data.fields.Name.value;
           // this.userPhotoUrl = data.fields.FullPhotoUrl.value || 'https://via.placeholder.com/150';  // Default image if no photo
        } else if (error) {
            console.error('Error retrieving user data: ', error);
        }
    }

    // Fetch Invoices when the Invoices tab is selected
    handleTabChange(event) {
        this.activeTab = event.target.value;

        if (this.activeTab === 'invoices') {
            this.fetchInvoices();
        } else if (this.activeTab === 'quotations') {
            this.fetchQuotations();
        }
    }

    fetchInvoices() {
        getInvoices({ userId: USER_ID })
            .then(result => {
                this.invoices = result;
            })
            .catch(error => {
                console.error('Error fetching invoices: ', error);
            });
    }

    fetchQuotations() {
        getQuotations({ userId: USER_ID })
            .then(result => {
                this.quotations = result;
            })
            .catch(error => {
                console.error('Error fetching quotations: ', error);
            });
    }
}