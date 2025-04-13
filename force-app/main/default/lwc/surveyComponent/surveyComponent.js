import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getSurveyActivities from '@salesforce/apex/VisitController.getSurveyActivities';
import createVisitTask from '@salesforce/apex/VisitController.createVisitTask';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Fields for Visit object query
const VISIT_TEMPLATE_FIELD = 'Visit.cgcloud__Visit_Template__c';

export default class SurveyComponent extends LightningElement {
    @api recordid; 
    
    @track surveyActivities = [];
    @track isLoading = true;
    @track error;


    

    // Get the Visit Template from the Visit record
    @wire(getRecord, { recordId: '$recordid', fields: [VISIT_TEMPLATE_FIELD] })
    wiredVisit({ error, data }) {
        if (data) {
            const visitTemplateId = getFieldValue(data, VISIT_TEMPLATE_FIELD);
            if (visitTemplateId) {
                this.loadSurveyActivities(visitTemplateId);
            } else {
                this.isLoading = false;
                this.error = 'No Visit Template associated with this Visit';
            }
        } else if (error) {
            this.isLoading = false;
            this.error = error.body.message;
        }
    }

    loadSurveyActivities(visitTemplateId) {
        getSurveyActivities({ visitTemplateId: visitTemplateId })
            .then(result => {
                this.surveyActivities = result;
                console.log('this.surveyActivities', this.surveyActivities);
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error.body.message;
                this.isLoading = false;
            });
    }

    handleChange(event) {
        const activityId = event.target.dataset.activityId;
        const feedback = event.target.value;
        
        // Create a new array with updated feedback
        this.surveyActivities = this.surveyActivities.map(item => {
            if (item.Id === activityId) {
                return { ...item, feedback };  // Update feedback for the corresponding activity
            }
            return item;
        });

        console.log('Updated survey activities:', this.surveyActivities);
    }

     // Helper method to show toast messages
     showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }

    handleSubmit(event) {
        const activityId = event.target.dataset.id; 
        const productId = event.target.dataset.productId; 
        const productName = event.target.dataset.productName;

        console.log('activityId:', activityId);
        console.log('productId:', productId);
        console.log('productName:', productName);

        // Find the activity with the corresponding activityId
        const activity = this.surveyActivities.find(item => item.Id === activityId);
        const feedback = activity ? activity.feedback : ''; // Get feedback from the updated activity

        console.log('feedback:', feedback);  // Verify if feedback is available

        // Create Visit Task using Apex
        createVisitTask({
            productId: productId,
            feedback: feedback,
            activityId: this.recordid,
            productname: productName
        })
        .then(result => {

            this.showToast('Success', 'Visit Task created successfully!', 'success');
            console.log(`Visit Task created for Activity ${activityId} with Product: ${productName}`);

            if (activity) {
                activity.feedback = '';  // Clear the feedback field in the activity
            }
            // Optionally, handle success (e.g., show success message)
        })
        .catch(error => {
            console.error(`Error creating Visit Task for Activity ${activityId}:`, error);
            // Optionally, handle error (e.g., show error message)
        });
    }
}