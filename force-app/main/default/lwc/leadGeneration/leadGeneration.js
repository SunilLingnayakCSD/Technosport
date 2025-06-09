import { LightningElement,track } from 'lwc';
import insertLead from '@salesforce/apex/leadGeneration.insertLead';
//import leadSoc from '@salesforce/resourceUrl/leadSoc';
//import Staffing from '@salesforce/resourceUrl/Staffing';

export default class LeadGeneration extends LightningElement {

    @track optionArray = [
    { label: 'VLSI', value: 'a00dL00000MYgGQQA1' },
    { label: 'Embedded', value: 'a00dL00000MZPhDQAX' },
    { label: 'Application Software', value: 'a00dL00000MZiJFQA1' }
];
               
   // leadSoc = leadSoc;
    //Staffing = Staffing;

    // Handle background image styling
    // get backgroundStyle() {
    //     return `background-image: url(${this.Staffing})`;
    // }

    // Lead form field values
    @track saluation = '';
    @track firstName = '';
    @track lastName = '';
    @track phoneNo = '';
    @track emailId = '';
    @track unit = ''; // Business Unit
    @track company = '';
    @track resource = '';

    // Handle changes in form inputs
    LeadChangeVal(event) {
        const { name, value } = event.target;
        if (name === 'saluation') this.saluation = value;
        if (name === 'firstName') this.firstName = value;
        if (name === 'lastName') this.lastName = value;
        if (name === 'phoneNo') this.phoneNo = value;
        if (name === 'emailId') this.emailId = value;
        if (name === 'BU') this.unit = value; // Handle Business Unit
        if (name === 'company') this.company = value;
        if (name === 'Required Resource') this.resource = value;
    }

    // Insert lead method
    insertLeadAction() {
        const leadObj = {
            sobjectType: 'Lead',
            FirstName: this.firstName,
            LastName: this.lastName,
            Phone: this.phoneNo,
            Email: this.emailId,
            Business_Unit_BU__c: this.unit,
            Company: this.company,
            Required_Resource__c: this.resource,
            Saluation__c: this.saluation,
            LeadSource: 'Web'
        };

        console.log('Lead details:', leadObj);

        // Insert the lead using Apex
        insertLead({ obj: leadObj })
            .then(response => {
                if (response) {
                    alert('Thank you for contacting us! Your lead has been created.');
                    window.location.reload();
                } else {
                    console.error('Lead insertion failed.');
                }
            })
            .catch(error => {
                console.error('Error inserting lead:', error);
            });
    }
}