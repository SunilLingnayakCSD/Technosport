import { LightningElement, track, wire } from 'lwc';
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
import ABSENT_FIELD from '@salesforce/schema/Attendance__c.absent__c';
import getCheckedAttendances from '@salesforce/apex/AttendanceController.getCheckedAttendances';
import { refreshApex } from '@salesforce/apex';

export default class CheckinComponent extends LightningElement {
    @track checkInTime = null;
    @track checkOutTime = null;
    @track timerRunning = false;    
    @track startTime = null;
    @track elapsedTimeInSeconds = 0;
    @track timerInterval;
    @track attendanceRecordId = null;
    @track currentLocation = null;
    @track locationError = null;
    @track isGettingLocation = false;
    attendanceRecords ;
    @track error;
    @track userId = USER_ID;
    @track records = false;
 
@track recordIdofattendednce
 
    connectedCallback(){
        this.getattendencedetailsonrefresh()
    }


    getattendencedetailsonrefresh() {
        getCheckedAttendances({ ownerId: this.userId }).then(data => {
            this.attendanceRecords = data;
            if (this.attendanceRecords && this.attendanceRecords.length > 0) {
                const record = this.attendanceRecords[0];
                this.records = record.Is_Checked_In__c;
                this.recordIdofattendednce = record.Id;
                this.checkInTime = new Date(record.Check_In__c);
    
                // If still checked in, check if it's been more than 24 hours
                if (this.records) {
                    const now = new Date();
                    const checkInDate = new Date(record.Check_In__c);
                    const hoursElapsed = (now - checkInDate) / (1000 * 60 * 60);

                    // const minutesElapsed = (now - checkInDate) / (1000 * 60); // minutes
                    // if (minutesElapsed >= 1) {
                    
                    // console.log('after 1 minute');
                    

                    
                   if (hoursElapsed >= 24 && !record.Check_Out__c && !record.Absent__c) {
                        // Mark as absent
                        const fields = {
                            Id: record.Id,
                            [ABSENT_FIELD.fieldApiName]: true,
                            [CHECKBOX_CLICKED.fieldApiName]: false
                        };
                        updateRecord({ fields })
                            .then(() => {
                                this.showToast('Info', 'User marked as absent (no checkout in 24 hrs)', 'info');
                            })
                            .catch(error => {
                                console.error('Error marking absent:', error);
                            });
                    }
    
                    this.calculateInitialDifference();
                    this.startTimer();
                } else {
                    this.stopTimer();
                }
            }
        }).catch(error => {
            console.log('Error in refresh:', error);
        });
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
    refreshData() {
        console.log('==================refresh==================');
        console.log('refresh logged');
        console.log('====================================');
      
        this.getattendencedetailsonrefresh()
    }
    
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
                this.recordIdofattendednce = record.Id;
                this.checkInTime = new Date().toLocaleString();
                this.startTime = Date.now();
                this.elapsedTimeInSeconds = 0;
                this.timerRunning = true;
                this.isGettingLocation = false;
                this.startTimer();
            })
            .then(() => {
                
                console.log('================start refreshing====================');
                console.log();
                console.log('====================================');
                this.refreshData()
                this.showToast('Success', 'Attendance refreshed successfully', 'success');
                this.dispatchEvent(new CustomEvent('checkin'));

                    // Add page reload here after everything is done
                setTimeout(() => {
                    window.location.reload();
                }, 1000); // Delay reload slightly to ensure toast shows

            })
            .catch(error => {
                this.isGettingLocation = false;
                this.showToast('Warning', error.message || 'Check-in recorded without location', 'warning');
            });
    }

    handleCheckOut() {
        if (!this.recordIdofattendednce) return;

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
                this.stopTimer();
                this.records = false;   
            })
            .then(() => {
                this.refreshData()
                this.showToast('Success', 'Attendance updated successfully', 'success');
            })
            .catch(error => {
                this.isGettingLocation = false;
                this.showToast('Warning', error.message || 'Check-out recorded without location', 'warning');
            });
    }

   
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
                    switch (error.code) {
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