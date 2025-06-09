import { LightningElement, api, track } from 'lwc';
import getVisitActivities from '@salesforce/apex/VisitActivityController.getVisitActivities';
import getPicklistAnswers from '@salesforce/apex/VisitActivityController.getPicklistAnswers';
import createVisitTasks from '@salesforce/apex/VisitActivityController.createVisitTasks';
import uploadAttachment from '@salesforce/apex/VisitActivityController.uploadAttachment';
import checkVisitTasksExist from '@salesforce/apex/VisitActivityController.checkVisitTasksExist';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class VisitActivityForm extends LightningElement {
    @api recordid;
    @track sections = [];
    @track isSubmitted = false;
    @track isLoading = false;
    photoMap = {};

    connectedCallback() {
        checkVisitTasksExist({ visitId: this.recordid }).then((exists) => {
            this.isSubmitted = exists;
            if (!exists) {
                this.loadActivities();
            }
        });
    }

    async loadActivities() {
        try {
            const activities = await getVisitActivities({ visitId: this.recordid });

            const questionMap = new Map();
            const sectionMap = new Map();

            for (let record of activities) {
                const section = record.Section__c || 'General';
                const question = {
                    Id: record.Id,
                    Name: record.Name,
                    Section__c: section,
                    Data_Type__c: record.Data_Type__c,
                    Required__c: record.Required__c,
                    Take_Picture__c: record.Take_Picture__c,
                    Parent_Based_Visibility__c: record.Parent_Based_Visibility__c,
                    Parent_Activity__c: record.Visit_Activity__c,
                    Answer__c: record.Answer__r?.Name,
                    selectedValue: '',
                    isVisible: !record.Parent_Based_Visibility__c,
                    isPicklist: record.Data_Type__c === 'Picklist',
                    isText: record.Data_Type__c === 'Text',
                    isDate: record.Data_Type__c === 'Date',
                    isNumber: record.Data_Type__c === 'Number',
                    picklistValues: [],
                    childQuestions: []
                };

                if (question.isPicklist) {
                    try {
                        question.picklistValues = await getPicklistAnswers({ visitActivityId: question.Id });
                    } catch (err) {
                        console.error('Picklist error for', question.Id, err);
                    }
                }

                questionMap.set(question.Id, question);

                if (!sectionMap.has(section)) {
                    sectionMap.set(section, []);
                }

                sectionMap.get(section).push(question);
            }

            for (let section of sectionMap.values()) {
                const ordered = [];
                const idToQuestion = new Map();
                section.forEach(q => idToQuestion.set(q.Id, q));

                const visited = new Set();

                function insertWithChildren(q) {
                    if (visited.has(q.Id)) return;
                    visited.add(q.Id);

                    ordered.push(q);
                    section.forEach(possibleChild => {
                        if (possibleChild.Parent_Activity__c === q.Id) {
                            insertWithChildren(possibleChild);
                        }
                    });
                }

                section.forEach(q => {
                    if (!q.Parent_Activity__c) {
                        insertWithChildren(q);
                    }
                });

                section.length = 0;
                section.push(...ordered);
            }

            this.sections = Array.from(sectionMap, ([name, questions]) => ({ name, questions }));
        } catch (error) {
            console.error('Error loading activities:', error);
        }
    }

    handleInputChange(event) {
        const questionId = event.target.dataset.id;
        const value = event.target.value;

        this.sections = this.sections.map(section => ({
            ...section,
            questions: section.questions.map(q => {
                if (q.Id === questionId) {
                    q.selectedValue = value;
                }
                return q;
            })
        }));

        this.updateVisibility();
    }

    updateVisibility() {
        this.sections = this.sections.map(section => ({
            ...section,
            questions: section.questions.map(q => {
                if (q.Parent_Based_Visibility__c && q.Parent_Activity__c && q.Answer__c) {
                    const parent = this.findQuestionById(q.Parent_Activity__c);
                    const parentValue = parent?.selectedValue?.trim();
                    q.isVisible = parentValue === q.Answer__c?.trim();
                }
                return q;
            })
        }));
    }

    findQuestionById(id) {
        for (let section of this.sections) {
            for (let q of section.questions) {
                if (q.Id === id) return q;
            }
        }
        return null;
    }

    handlePhotoCapture(event) {
        const questionId = event.currentTarget.dataset.id;

        const input = document.createElement('input');
        input.type = 'file';
        input.accept = 'image/*';
        // input.capture = 'environment';

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

                    this.sections = this.sections.map(section => ({
                        ...section,
                        questions: section.questions.map(q => {
                            if (q.Id === questionId && q.isText && q.Take_Picture__c) {
                                return { ...q, selectedValue: 'Uploaded' };
                            }
                            return q;
                        })
                    }));
                };
                reader.readAsDataURL(file);
            }
        };

        input.click();
    }

    formatDate(inputDate) {
        const date = new Date(inputDate);
        const day = String(date.getDate()).padStart(2, '0');
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const year = date.getFullYear();
        return `${day}-${month}-${year}`;
    }

    async handleSubmit() {
        this.isLoading = true;
        const taskList = [];
        const missingRequired = [];

        this.sections.forEach(section => {
            section.questions.forEach(q => {
                if (!q.isVisible) return;

                const value = q.selectedValue?.toString().trim();

                if (q.Required__c && (!value || value === '')) {
                    missingRequired.push(q.Name);
                }

                if (value && value !== '') {
                    let answer = value;
                    if (q.isDate) {
                        answer = this.formatDate(value);
                    }

                    taskList.push({
                        question: q.Name,
                        answer: answer,
                        questionId: q.Id
                    });
                }
            });
        });

        if (missingRequired.length > 0) {
            this.showToast(
                'Required Fields Missing',
                'Please answer required questions: ' + missingRequired.join(', '),
                'error'
            );
            this.isLoading = false;
            return;
        }

        try {
            const taskIds = await createVisitTasks({
                visitId: this.recordid,
                taskJson: JSON.stringify(taskList)
            });

            for (let i = 0; i < taskIds.length; i++) {
                const task = taskList[i];
                const photo = this.photoMap[task.questionId];
                if (photo) {
                    await uploadAttachment({
                        parentId: taskIds[i],
                        base64Data: photo.base64,
                        fileName: photo.fileName
                    });
                }
            }

            this.isSubmitted = true;
            this.showToast('Success', 'Store check done for the visit.', 'success');
        } catch (err) {
            console.error('Submission error:', err);
            this.showToast('Error', 'An error occurred while submitting.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}