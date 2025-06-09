import { LightningElement, track } from 'lwc';
import getVisits from '@salesforce/apex/LoginUserVisitController.getVisits';
import checkIfUserCheckedIn from '@salesforce/apex/LoginUserVisitController.checkIfUserCheckedIn';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class VisitPlanner extends NavigationMixin(LightningElement) {
    @track visits = [];
    @track dailySelected = true;
    @track fromDate;
    @track toDate;
    @track isLoading = false;

    get dailyButtonVariant() {
        return this.dailySelected ? 'brand' : 'neutral';
    }

    get weeklyButtonVariant() {
        return this.dailySelected ? 'neutral' : 'brand';
    }

    connectedCallback() {
        this.loadVisits(); // Load today's visits by default
    }

    showDailyView() {
        this.dailySelected = true;
        this.fromDate = null;
        this.toDate = null;
        this.loadVisits();
    }

    showWeeklyView() {
        this.dailySelected = false;
        const today = new Date();
        const day = today.getDay();
        const diffToMonday = day === 0 ? 6 : day - 1;

        const monday = new Date(today);
        monday.setDate(today.getDate() - diffToMonday);

        const sunday = new Date(monday);
        sunday.setDate(monday.getDate() + 6);

        this.fromDate = this.formatDate(monday);
        this.toDate = this.formatDate(sunday);

        this.loadVisits();
    }
    
    handleFromChange(event) {
        this.fromDate = event.target.value;
    }

    handleToChange(event) {
        this.toDate = event.target.value;
    }

    formatDate(date) {
        return date.toISOString().split('T')[0];
    }

    loadVisits() {
        this.isLoading = true;

        const viewType = this.dailySelected ? 'daily' : 'weekly';

        getVisits({
            viewType: viewType,
            startDate: this.fromDate,
            endDate: this.toDate
        })
            .then((result) => {
                this.visits = result;
                this.visits=this.visits.map((visit)=>({
                    ...visit,
                    formattedVisitDate: this.formatDate(new Date(visit.PlannedVisitStartTime))
                }))
                this.isLoading = false;
            })
            .catch((error) => {
                console.error('Error loading visits', error);
                this.isLoading = false;
            });
    }

            navigateToRecord(event) {
                const visitId = event.currentTarget.dataset.id;
            
                checkIfUserCheckedIn()
                    .then(result => {
                        console.log('result---->', result);
            
                        if (result === 'Success') {
                            this[NavigationMixin.Navigate]({
                                type: 'standard__recordPage',
                                attributes: {
                                    recordId: visitId,
                                    objectApiName: 'Visit',
                                    actionName: 'view'
                                }
                            });
                        } else {
                            this.showErrorToast(result)
                                .then(() => {
                                    this.refreshComponent();
                                });
                        }
                    })
                    .catch(error => {
                        this.showErrorToast(error.body?.message || 'An unexpected error occurred.')
                            .then(() => {
                                this.refreshComponent();
                            });
                    });
            }
            
            showErrorToast(message) {
                return new Promise((resolve) => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Check-In Required',
                            message,
                            variant: 'error'
                        })
                    );
                    // Add a short delay to allow toast to render before resolving
                    setTimeout(() => {
                        resolve();
                    }, 1000); // 1 second delay
                });
            }
            

            refreshComponent() {
                this.loadVisits(); // Reloads visits
            }
            
}