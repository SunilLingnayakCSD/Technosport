import { api, LightningElement, track,wire } from 'lwc';
import getCheckedVisits from '@salesforce/apex/VisitController.getCheckedVisits';
export default class MBL_Application_main_Component extends LightningElement {
    @api recordId;
       photoMap = {};
        
    connectedCallback() {
      
       this.loadVisitData();
        console.log('==========888888888888==========================');
        console.log(this.recordId);
        console.log('====================================');
    }
    @track isCheckedOut;
   @track visitRecords
 @track visitStart;

loadVisitData() {
    getCheckedVisits({ recordId: this.recordId })
        .then(result => {
            
                this.visitRecords = result;
                const visitRecord = result[0];
                this.isCheckedOut = visitRecord.Is_Checked_out__c;
                this.visitStart=visitRecord.Is_Checked_In__c
                console.log(this.isCheckedOut, '***********************');
           
        })
        .catch((error) => {
            console.error('Error loading visit records:', error);
        });
}
    

    
    handleupdate(event){
        this.visitStart=event.detail.check
        this.isCheckedOut=!this.visitStart
        console.log('====================================');
        console.log(this.visitStart);
        console.log('====================================');
    }
    
}