import { LightningElement, track, wire, api } from 'lwc';
import {  updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import USER_ID from '@salesforce/user/Id';
import VISIT_OBJECT from '@salesforce/schema/Visit';
import CHECKIN_FIELD from '@salesforce/schema/Visit.ActualVisitStartTime';
import CHECKOUT_FIELD from '@salesforce/schema/Visit.ActualVisitEndTime';
import LATITUDE_TEXT_FIELD from '@salesforce/schema/Visit.Latitude__c'; 
import LONGITUDE_TEXT_FIELD from '@salesforce/schema/Visit.Longitude__c'; 
import CHECKBOX_CLICKED from '@salesforce/schema/Visit.Is_Checked_In__c';
import CHECKBOX_CHECKOUT from '@salesforce/schema/Visit.Is_Checked_out__c'
import STATUS from '@salesforce/schema/Visit.Status';
import PLANNED_END_FIELD from '@salesforce/schema/Visit.PlannedVisitEndTime';
import getCheckedVisits from '@salesforce/apex/VisitController.getCheckedVisits';
import { refreshApex } from '@salesforce/apex';

export default class VisitComponent extends LightningElement {
    @api recordid;

    // Tracked properties
    @track checkInTime = null;
    @track checkOutTime = null;
    @track timerRunning = false;    
    @track startTime = null;
    @track elapsedTimeInSeconds = 0;
    @track timerInterval;
    @track currentLocation = null;
    @track locationError = null;
    @track isGettingLocation = false;
    @track visitRecords = [];
    @track error;
    @track userId = USER_ID;
    @track records = false;
    @track recordIdofattendednce;
    @track plannedStartTime;
    @track plannedEndTime;
    @track isCheckedIn = false;
    @track showsuccess = false;


    // Wire method to fetch records
@wire(getCheckedVisits, { recordId: '$recordid' })
wiredAttendances(result) {
    this.visitRecords = result;
    const { error, data } = result;

    if (data && data.length > 0) {
        this.visitRecords = data;
        const visitRecord = data[0];

        this.records = visitRecord.Is_Checked_In__c;
        this.plannedStartTime = visitRecord.PlannedVisitStartTime;
        this.plannedEndTime = visitRecord.PlannedVisitEndTime;
        this.recordIdofattendednce = visitRecord.Id;
        this.isCheckedIn = visitRecord.Is_Checked_In__c;

        // Check for Is_Checked_out__c field value
        const isCheckedOut = visitRecord.Is_Checked_out__c;
        console.log('isCheckedOut: ' + isCheckedOut);
        
        
        
        // If the visit is checked out, show the success message
        if (isCheckedOut) {
            this.showsuccess = true;
            
        } else {
            this.showsuccess = false;
        }

        if (visitRecord.ActualVisitStartTime) {
            this.checkInTime = new Date(visitRecord.ActualVisitStartTime);
        }

        if (visitRecord.ActualVisitEndTime) {
            this.checkOutTime = new Date(visitRecord.ActualVisitEndTime);
        }

        if (this.isCheckedIn) {
            this.calculateInitialDifference();
            this.startTimer();
        }
    } else if (error) {
        console.error('Error:', error);
        this.showToast('Error', 'Failed to load visit data', 'error');
    }
}


    calculateInitialDifference() {
        const now = new Date();
        this.elapsedTimeInSeconds = Math.floor((now - this.checkInTime) / 1000);
    }

    startTimer() {
        if (!this.timerInterval) {
            this.timerInterval = setInterval(() => {
                this.elapsedTimeInSeconds++;
            }, 1000);
        }
    }

    stopTimer() {
        if (this.timerInterval) {
            clearInterval(this.timerInterval);
            this.timerInterval = null;
        }
    }

    // Formatting getters
    get formattedDays() {
        const days = Math.floor(this.elapsedTimeInSeconds / (3600 * 24));
        return days.toString().padStart(2, '0');
    }

    get formattedHours() {
        const hours = Math.floor((this.elapsedTimeInSeconds % (3600 * 24)) / 3600);
        return hours.toString().padStart(2, '0');
    }

    get formattedMinutes() {
        const minutes = Math.floor((this.elapsedTimeInSeconds % 3600) / 60);
        return minutes.toString().padStart(2, '0');
    }

    get formattedSeconds() {
        const seconds = this.elapsedTimeInSeconds % 60;
        return seconds.toString().padStart(2, '0');
    }

    handleCheckIn() {
        this.isGettingLocation = true;
        this.showToast('Info', 'Getting your location...', 'info');
        
        this.getCurrentLocation()
            .then(coords => {
                this.currentLocation = coords;
                
                const fields = {
                    [CHECKIN_FIELD.fieldApiName]: new Date().toISOString(),
                    [LATITUDE_TEXT_FIELD.fieldApiName]: coords.latitude.toString(),
                    [LONGITUDE_TEXT_FIELD.fieldApiName]: coords.longitude.toString(),
                    [CHECKBOX_CLICKED.fieldApiName]: true,
                    Id: this.recordid // Use the current recordId
                };
                
                // If there's an existing record, update it
                return updateRecord({
                    fields // Do not include apiName here
                });
            })
            .then(() => {
                this.checkInTime = new Date();
                this.startTime = Date.now();
                this.elapsedTimeInSeconds = 0;
                this.timerRunning = true;
                this.isCheckedIn = true;
                this.isGettingLocation = false;
               
                this.startTimer();
                
                return refreshApex(this.visitRecords);
            })
            .then(() => {
                this.showToast('Success', 'Checked in successfully with location', 'success');
                const deleteSelectedInParent = new CustomEvent('updatecheck', {
                    bubbles: true,
                    composed: true,
                    detail: { check: true }
                });
                this.dispatchEvent(deleteSelectedInParent);
            })
            .catch(error => {
                console.error('Error:', error);
                this.isGettingLocation = false;
                this.showToast('Warning', error.message || 'Check-in recorded without location', 'warning');
            });
    }
    

    handleCheckOut() {
        if (!this.recordid) { // Ensure there is a valid recordId
            this.showToast('Error', 'No visit record found to check out', 'error');
            return;
        }
    
        this.isGettingLocation = true;
        this.showToast('Info', 'Getting your location for checkout...', 'info');
    
        this.getCurrentLocation()
            .then(coords => {
                this.currentLocation = coords;
    
                const fields = {
                    Id: this.recordid, // Ensure you're updating the recordId for the check-out record
                    [CHECKOUT_FIELD.fieldApiName]: new Date().toISOString(),
                    [CHECKBOX_CLICKED.fieldApiName]: false,
                    [LATITUDE_TEXT_FIELD.fieldApiName]: coords.latitude.toString(),
                    [LONGITUDE_TEXT_FIELD.fieldApiName]: coords.longitude.toString(),
                    [CHECKBOX_CHECKOUT.fieldApiName]: true,
                    [STATUS.fieldApiName]: 'Completed'
                };
    
                // Update the record with checkout time
                return updateRecord({ fields });
            })
            .then(() => {
                // After successfully updating the checkout time
                this.checkOutTime = new Date();
                this.timerRunning = false;
                this.isCheckedIn = false;  // Mark the user as checked out
                this.isGettingLocation = false;
                this.showsuccess = true; // Show success message
                
                // Stop the timer
                this.stopTimer();
    
                return refreshApex(this.visitRecords);
            })
            .then(() => {
                this.showToast('Success', 'Checked out successfully with location', 'success');
                const deleteSelectedInParent = new CustomEvent('updatecheck', {
                    bubbles: true,
                    composed: true,
                    detail: { check: false }
                });
                console.log('====================================');
                console.log('called back to parent');
                console.log('====================================');
                this.dispatchEvent(deleteSelectedInParent);
            })
            .catch(error => {
                console.error('Error:', error);
                this.isGettingLocation = false;
                this.showToast('Warning', error.message || 'Check-out recorded without location', 'warning');
            });
    }
    
    

    // Get current location using browser geolocation
    getCurrentLocation() {
        return new Promise((resolve, reject) => {
            if (!navigator.geolocation) {
                reject(new Error('Geolocation is not supported by your browser'));
                return;
            }

            const options = {
                enableHighAccuracy: true,
                timeout: 10000,
                maximumAge: 0
            };

            navigator.geolocation.getCurrentPosition(
                position => {
                    resolve({
                        latitude: position.coords.latitude.toFixed(6),
                        longitude: position.coords.longitude.toFixed(6),
                        accuracy: position.coords.accuracy
                    });
                },
                error => {
                    let message = 'Could not get location';
                    switch(error.code) {
                        case error.PERMISSION_DENIED:
                            message = 'Location permission denied. Please enable location services.';
                            break;
                        case error.POSITION_UNAVAILABLE:
                            message = 'Location information is unavailable.';
                            break;
                        case error.TIMEOUT:
                            message = 'The request to get location timed out.';
                            break;
                    }
                    reject(new Error(message));
                },
                options
            );
        });
    }

    // Helper method to show toast messages
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }

    // Display current location in UI
    get formattedLocation() {
        if (!this.currentLocation) return 'Location not available';
        return `Latitude: ${this.currentLocation.latitude}, Longitude: ${this.currentLocation.longitude}`;
    }

    // Compute property to disable check-in button
    get disableCheckIn() {
        return this.isGettingLocation || this.isCheckedIn;
    }

    // Compute property to disable check-out button
    get disableCheckOut() {
        return this.isGettingLocation || !this.isCheckedIn;
    }
}