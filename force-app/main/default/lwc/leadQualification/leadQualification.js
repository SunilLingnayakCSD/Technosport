import { LightningElement, api, track } from 'lwc';

export default class LeadQualification extends LightningElement {
    @api recordId; // gets passed by Lightning Record Page
    @track isshow = false;
    @track flowName;
    @track flowInputVariables = [];

    launchQualify() {
        this.flowName = 'Qualify_Lead_and_Calling_Done';
        this.startFlow();
    }

    launchUnqualify() {
        this.flowName = 'Unqualify_Lead_and_complete_the_task';
        this.startFlow();
    }

    startFlow() {
        this.flowInputVariables = [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }
        ];
        this.isshow = true;
        console.log(`🚀 Starting flow: ${this.flowName} with recordId: ${this.recordId}`);
    }

    handleFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.isshow = false;
        }
    }
}