import { api, LightningElement, track } from 'lwc';
import getVisitActivities from '@salesforce/apex/SaveAttachmentController.getVisitActivities';
import createVisitTasks from '@salesforce/apex/SaveAttachmentController.createVisitTasks';
import uploadAttachment from '@salesforce/apex/SaveAttachmentController.uploadAttachment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class MBL_Application_main_Component extends LightningElement {
    @api recordId;
       photoMap = {};
        @track questions = [];
    connectedCallback() {
       this.loadActivities();
    
        console.log('==========888888888888==========================');
        console.log(this.recordId);
        console.log('====================================');
    }
    
 async loadActivities() {
        try {
            const result = await getVisitActivities({ visitId: this.recordId });
            this.questions = result
                .filter(q => q.Order_Related__c && q.Data_Type__c === 'Text')
                .map(q => ({
                    ...q,
                    selectedValue: ''
                }));
        } catch (error) {
            this.showToast('Error loading questions', error.body?.message || error.message, 'error');
        }
    }

     handleInputChange(event) {
        const questionId = event.target.dataset.id;
        const value = event.target.value;

        this.questions = this.questions.map(q => {
            if (q.Id === questionId) {
                return { ...q, selectedValue: value };
            }
            return q;
        });
    }
     handlePhotoCapture(event) {
        const questionId = event.currentTarget.dataset.id;
        const input = document.createElement('input');
        input.type = 'file';
        input.accept = 'image/*';
        input.capture = 'environment';

        input.onchange = () => {
            const file = input.files[0];
            if (file) {
                const reader = new FileReader();
                reader.onloadend = () => {
                    const base64 = reader.result.split(',')[1];
                    this.photoMap[questionId] = {
                        fileName: file.name,
                        base64
                    };

                    this.questions = this.questions.map(q => {
                        if (q.Id === questionId) {
                            return { ...q, selectedValue: 'Uploaded' };
                        }
                        return q;
                    });
                };
                reader.readAsDataURL(file);
            }
        };

        input.click();
    }

    async handleSubmit() {
        const tasks = this.questions
            .filter(q => q.selectedValue)
            .map(q => ({
                question: q.Name,
                answer: q.selectedValue,
                questionId: q.Id
            }));

        try {
            const taskIds = await createVisitTasks({
                visitId: this.recordId,
                taskJson: JSON.stringify(tasks)
            });

            for (let i = 0; i < taskIds.length; i++) {
                const task = tasks[i];
                const photo = this.photoMap[task.questionId];
                if (photo) {
                    await uploadAttachment({
                        parentId: taskIds[i],
                        base64Data: photo.base64,
                        fileName: photo.fileName
                    });
                }
            }

            this.showToast('Success', 'Responses submitted successfully.', 'success');
        } catch (err) {
            this.showToast('Error', err.body?.message || err.message, 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    @track showportal=false
    handlebuttonclick(){
        this.showportal=true
    }
}