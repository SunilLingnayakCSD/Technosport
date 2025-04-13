import { LightningElement, track ,wire} from 'lwc';
import { createRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import USER_ID from '@salesforce/user/Id';
import ATTENDANCE_OBJECT from '@salesforce/schema/Attendance__c';
import CHECKIN_FIELD from '@salesforce/schema/Attendance__c.Check_In__c';
import CHECKOUT_FIELD from '@salesforce/schema/Attendance__c.Check_Out__c';
import USER_FIELD from '@salesforce/schema/Attendance__c.User__c';
import LATITUDE_TEXT_FIELD from '@salesforce/schema/Attendance__c.Latitude__c'; 
import LONGITUDE_TEXT_FIELD from '@salesforce/schema/Attendance__c.Longitude__c'; 
import CHECKBOX_CLICKED from '@salesforce/schema/Attendance__c.Is_Checked_In__c';
import getCheckedAttendances from '@salesforce/apex/AttendanceController.getCheckedAttendances';
import { refreshApex } from '@salesforce/apex';

export default class CheckinComponent extends LightningElement {
    // Tracked properties
    @track checkInTime = null;
    @track checkOutTime = null;
    @track timerRunning ;    
    @track startTime = null;
    @track elapsedTimeInSeconds = 0;
    @track timerInterval;
    @track attendanceRecordId = null;
    @track currentLocation = null;
    @track locationError = null;
    @track isGettingLocation = false;
    @track attendanceRecords = [];
    @track error;
    @track userId = USER_ID;
    @track records = false;


    // Wire method to fetch records
    @wire(getCheckedAttendances, { ownerId: '$userId' })
    wiredAttendances(result) {
          this.attendanceRecords = result;
        const{error,data}=result
        if (data && data.length > 0) {
            this.attendanceRecords = data;
            this.records = this.attendanceRecords[0].Is_Checked_In__c;
            this.checkInTime = new Date(this.attendanceRecords[0].Check_In__c);
            this.recordIdofattendednce=this.attendanceRecords[0].Id
            if (this.records) {
                this.calculateInitialDifference();
                this.startTimer();
            }
        } else if (error) {
            console.error('Error:', error);
        }
    }

    calculateInitialDifference() {
        const now = new Date();
        this.elapsedTimeInSeconds = Math.floor((now - this.checkInTime) / 1000);
    }

    startTimer() {
        this.timerInterval = setInterval(() => {
            this.elapsedTimeInSeconds++;
        }, 1000);
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

    // disconnectedCallback() {
    //     this.stopTimer();
    // }

    

    // Handle check-in with location
    handleCheckIn() {
        this.isGettingLocation = true;
        this.getCurrentLocation()
            .then(coords => {
                this.currentLocation = coords;
                
                const fields = {
                    [CHECKIN_FIELD.fieldApiName]: new Date().toISOString(),
                    [USER_FIELD.fieldApiName]: USER_ID,
                    [LATITUDE_TEXT_FIELD.fieldApiName]: coords.latitude.toString(),
                    [LONGITUDE_TEXT_FIELD.fieldApiName]: coords.longitude.toString(),
                    [CHECKBOX_CLICKED.fieldApiName]: true
                };
                
                return createRecord({
                    apiName: ATTENDANCE_OBJECT.objectApiName,
                    fields
                });
            })
            .then(record => {
                
                this.recordIdofattendednce = record.id;
                this.checkInTime = new Date().toLocaleString();
                this.startTime = Date.now();
                this.elapsedTimeInSeconds = 0;
                this.timerRunning = true;
                this.isGettingLocation = false;
                
                // Start timer
                this.timerInterval = setInterval(() => {
                    this.elapsedTimeInSeconds = Math.floor((Date.now() - this.startTime) / 1000);
                }, 1000);
                refreshApex(this.attendanceRecords).then(result=>{
                    console.log(result);
                    this.showToast('Success', 'Attendance refreshed recorded successfully', 'success')
                    
                }).catch(error=>{
                    console.log(error);
                    this.showToast('Error', 'Attendance not refreshed recorded successfully', 'Error')
                    
                })
                this.showToast('Success', 'Checked in with location coordinates', 'success');
            })
            .catch(error => {
                console.error('Error:', error);
                this.isGettingLocation = false;
                this.showToast('Warning', error.message || 'Check-in recorded without location', 'warning');
            });
    }

    // Handle check-out with location
    handleCheckOut() {
        console.log(this.recordIdofattendednce,'iiiiiiiiiiiiiiiiii');
        
        if (!this.recordIdofattendednce) return;
        console.log('hiiiiiiiiiiii');
        
        this.isGettingLocation = true;
        this.getCurrentLocation()
            .then(coords => {
                this.currentLocation = coords;
                
                const fields = {
                    'Id': this.recordIdofattendednce,
                    [CHECKOUT_FIELD.fieldApiName]: new Date().toISOString(),
                    [CHECKBOX_CLICKED.fieldApiName]: false
                };
                
                return updateRecord({ fields });
            })
            .then(() => {
                this.checkOutTime = new Date().toLocaleString();
                this.timerRunning = false;
                this.isGettingLocation = false;
                // this.stopTimer();
                
                if (this.timerInterval) {
                    clearInterval(this.timerInterval);
                    this.timerInterval = null;
                }
                refreshApex(this.attendanceRecords).then(result=>{
                    console.log(result);
                    this.showToast('Success', 'Attendance refreshed recorded successfully', 'success')
                    
                }).catch(error=>{
                    console.log(error);
                    this.showToast('Error', 'Attendance not refreshed recorded successfully', 'Error')
                    
                })
                
                this.showToast('Success', 'Checked out with location coordinates', 'success');
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

    // Formatted time getters
    get formattedHours() {
        const hours = Math.floor(this.elapsedTimeInSeconds / 3600);
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

    // Display current location in UI
    get formattedLocation() {
        if (!this.currentLocation) return 'Location not available';
        return `Latitude: ${this.currentLocation.latitude}, Longitude: ${this.currentLocation.longitude}`;
    }
}