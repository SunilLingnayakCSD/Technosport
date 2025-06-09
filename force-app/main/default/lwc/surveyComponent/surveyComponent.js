import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getSurveyActivities from '@salesforce/apex/VisitController.getSurveyActivities';
import createVisitTask from '@salesforce/apex/VisitController.createVisitTask';
import getAllProducts from '@salesforce/apex/VisitController.getAllProducts'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import DownArrow from '@salesforce/resourceUrl/DownArrow';
import saveAttachmentToVisitTask from '@salesforce/apex/VisitController.saveAttachmentToVisitTask'

const VISIT_TEMPLATE_FIELD = 'Visit.cgcloud__Visit_Template__c';

export default class SurveyComponent extends LightningElement {
    @api recordid;

    @track surveyActivities = [];
    @track allProducts = []; 
    @track surveyActivitiesOriginal = []; 
    @track currentFilter = 'Survey Product'; 
    @track isLoading = true;
    @track error;
    @track showfeedback = false;
    @track uploadedFileName = '';
    @track fileData = '';
    DownArrow = DownArrow;

    osType;
    @wire(getRecord, { recordId: '$recordid', fields: [VISIT_TEMPLATE_FIELD] })
    wiredVisit({ error, data }) {
        if (data) {
            this.visitTemplateId = getFieldValue(data, VISIT_TEMPLATE_FIELD);
            if (this.visitTemplateId) {
                this.loadSurveyActivities(this.visitTemplateId);
            } else {
                this.isLoading = false;
                this.error = 'No Visit Template associated with this Visit';
            }
        } else if (error) {
            this.isLoading = false;
            this.error = error.body.message;
        }
    }
    connectedCallback() {
        this.osType = this.getMobileOperatingSystem();
        console.log('OS Type:', this.osType);
    }

    getMobileOperatingSystem() {
        const userAgent = navigator.userAgent || navigator.vendor || window.opera;

        const isIOS = /iPad|iPhone|iPod|iOS/.test(userAgent)
        || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);

    if (isIOS) {
        return 'iOS';
    }
        if (/android/i.test(userAgent)) {
            return 'Android';
        }

        return 'unknown';
    }

    renderedCallback() {
        this.initializeAccordion();
    }
    initializeAccordion() {

        const acc = this.template.querySelectorAll('.accordion');


        if (acc.length > 0) {
            acc.forEach((element) => {

                if (!element.hasAttribute('data-listener')) {
                    element.addEventListener('click', () => this.toggleAccordion(element));

                    element.setAttribute('data-listener', 'true');
                }
            });
        }
    }

    toggleAccordion(element) {

        element.classList.toggle('active');


        const panel = element.nextElementSibling;


        if (panel) {
            panel.classList.toggle('show');
        }
    }

    loadSurveyActivities(visitTemplateId) {
        this.isLoading = true;
        getSurveyActivities({ visitTemplateId })
            .then(result => {
                this.surveyActivitiesOriginal = [...result]; 
                this.surveyActivities = result.map(item => ({
                    ...item,
                    isvisit: false
                }));
                
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error.body.message;
                this.isLoading = false;
            });
    }
    handlebtnClick() {
        this.showfeedback = true;
    }


    handleFileUpload(event) {
        const files = event.target.files;
        const activityId = event.target.dataset.activityId;
        console.log('activityId : ', activityId);
        const fileType = event.target.dataset.fileType; 

        if (!files || !files.length) return;

        const fileReaders = [];
        const fileDataList = [];

        Array.from(files).forEach(file => {
            const reader = new FileReader();

            fileReaders.push(new Promise(resolve => {
                reader.onloadend = () => {
                    const base64 = reader.result.split(',')[1];
                    fileDataList.push({
                        fileName: file.name,
                        base64: base64,
                         contentType: this.osType!=='iOS'?'':file.type
                    });
                    resolve();
                };
                reader.readAsDataURL(file);
            }));
        });

        Promise.all(fileReaders).then(() => {
            this.surveyActivities = this.surveyActivities.map(item => {
                if (item.Id === activityId) {
                    if (fileType === 'tag') {
                        return { ...item, tagImage: fileDataList[0] };
                    } 
                }
                console.log('item : ', item);
                return item;
            });
            console.log(' this.surveyActivities : ', JSON.stringify(this.surveyActivities, null, 2));
            console.log('OUTPUT : ',);
            console.log('Updated activity with file upload');
        });
    }



    productBatchChange(event) {
        const activityId = event.target.dataset.activityId;
        const productChange = event.target.value;
        console.log("productChange---------->", productChange);
        this.surveyActivities = this.surveyActivities.map(item => {
            if (item.Id === activityId) {
                return { ...item, productChange };  
            }
            return item;
        });

        console.log('Updated survey activities:', this.surveyActivities);
    }


    handleChange(event) {
        const activityId = event.target.dataset.activityId;
        const feedback = event.target.value;
        this.surveyActivities = this.surveyActivities.map(item => {
            if (item.Id === activityId) {
                return { ...item, feedback }; 
            }
            return item;
        });

        console.log('Updated survey activities:', this.surveyActivities);
    }
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }


    handleFilterChange(event) {
        const selectedValue = event.target.value;
        this.currentFilter = selectedValue;

        if (selectedValue === 'all products') {
            this.fetchAllProducts();
        } else if (selectedValue === 'Survey Product') {
            if (this.visitTemplateId) {
                this.loadSurveyActivities(this.visitTemplateId);
            } else {
                this.error = 'Visit Template not loaded';
            }
        }
    }


    fetchAllProducts() {
        this.isLoading = true;
        getAllProducts()
            .then(result => {
                this.allProducts = result.map(product => ({
                    Id: product.Id,
                    Product__r: {
                        Id: product.Id,
                        Name: product.Name,
                        URL__c: product.URL__c
                    },
                    feedback: '',
                    productChange: ''
                }));
                this.surveyActivities = [...this.allProducts];
                this.isLoading = false;
            })
            .catch(error => {
                this.error = error.body.message;
                this.isLoading = false;
            });
    }


    handleSearch(event) {
        const searchTerm = event.target.value.toLowerCase();

        if (this.currentFilter === 'all products') {
            this.surveyActivities = this.allProducts.filter(product => {
                const name = product.Product__r?.Name;
                return name && name.toLowerCase().includes(searchTerm);
            });
        } else if (this.currentFilter === 'Survey Product') {
            this.surveyActivities = this.surveyActivitiesOriginal.filter(product => {
                const name = product.Product__r?.Name;
                return name && name.toLowerCase().includes(searchTerm);
            });
        }
    }

    handleSubmit(event) {
        const activityId = event.target.dataset.id;
        const productId = event.target.dataset.productId;
        const productName = event.target.dataset.productName;
        let activity = this.surveyActivities.find(item => item.Id === activityId);
        const feedback = activity ? activity.feedback : ''; 
        const productChange = activity ? activity.productChange : '';
        const tagImage = activity?.tagImage || null;
        let missingFields = [];
       // this.isLoading=true

        if (!productChange) {
            missingFields.push('Product Batch');
            this.isLoading=false
        }
        if (!feedback) {
            missingFields.push('Feedback');
            this.isLoading=false
        }
        if (!tagImage) {
            missingFields.push('Tag Image');
            this.isLoading=false
        }

        if (missingFields.length > 0) {
            const message = `Please fill in the following required field(s): ${missingFields.join(', ')}`;
            this.showToast('Missing Required Fields', message, 'error');
            this.isLoading=false
            return;
        }
        createVisitTask({
            productId: productId,
            feedback: feedback,
            productChange: productChange,
            activityId: this.recordid,
            productname: productName,
            tagImage: JSON.stringify(tagImage)
           
        })
            .then(result => {
              
                this.showToast('Success', 'Visit Task created successfully!', 'success');
                console.log(`Visit Task created for Activity ${activityId} with Product: ${productName}`);
                activity = { ...activity, visitTask: result,isvisit:true }
                                this.surveyActivities = this.surveyActivities.map(item => {
                    if (item.Id === activityId) {
                        return activity;
                    }
                    return item;
                });
                console.log('(*********)',JSON.stringify(this.surveyActivities, null, 2));
                
                if (activity) {
                    activity.feedback = '';
                    activity.productChange = '';  
                }
                this.isLoading=false
            })
            .catch(error => {
                this.isLoading=false
                console.log('OUTPUT : ', error);
                const errorMessage = error?.body?.message || 'An unexpected error occurred';

                if (errorMessage.includes('Feedback already submitted')) {
                    this.showToast('Duplicate Submission', errorMessage, 'warning');
                } else {
                    this.showToast('Error', errorMessage, 'error');
                }
                console.error(`Error creating Visit Task for Activity ${activityId}:`, error);
            });
    }

    handleIndividualFileUpload(event) {
        const file = event.target.files[0];
        const visitTaskId = event.target.dataset.visitid; 
        
        if (!file || !visitTaskId) {
            console.error('Missing file or visitTask ID');
            
            return;
        }
    
        const reader = new FileReader();
        reader.onloadend = () => {
            const base64 = reader.result.split(',')[1];
    
          
            saveAttachmentToVisitTask({
                fileName: file.name,
                base64Data: base64,
                contentType: file.type,
                visitTaskId: visitTaskId
            })
            .then(() => {
               
                console.log('File uploaded successfully');
                this.showToast('Success', 'File uploaded successfully!', 'success');
               
            })
            .catch(error => {
                console.error('Error uploading file:', error);
                this.showToast('Error', 'Error uploading file:!', 'error');
                
            });
        };
        reader.readAsDataURL(file);
    }
    
}