import { LightningElement, api, wire, track } from 'lwc';
import getVisitJobQuestions from '@salesforce/apex/VisitDataController.getVisitJobQuestions';

export default class VisitJobQuestions extends LightningElement {
    @api recordId; 
    @track questions = [];
    @track surveys = [];
    error;

    @wire(getVisitJobQuestions, { visitId: '$recordId' })
    wiredVisitJobQuestions({ error, data }) {
        if (data) {
            console.log('Fetched Visit Job Questions:', data);
            this.questions = data.questions || [];
            this.surveys = data.surveys || [];
        } else if (error) {
            this.error = error;
            console.log('Error fetching visit job questions:', error);
        }
    }
}