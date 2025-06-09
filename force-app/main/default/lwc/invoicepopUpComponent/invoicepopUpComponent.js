import { LightningElement, api, wire,track } from 'lwc';
import getLocation from '@salesforce/apex/invoicepopupController.getLocation';
import getvisitLocation from '@salesforce/apex/invoicepopupController.getvisitLocation'


export default class InvoicepopUpComponent extends LightningElement {
//     @api recordId;
// mapMarkers = [];
// @track centerLocation = {};
// currentlat;
// currentlang;
 
//     @wire(getLocation, { recordId: '$recordId' })
//     wireGetrecords({ data, error }) {
//         if (data) {
//             this.details = data[0];
//             console.log('OUTPUT ---------->: ', this.details);
//             this.currentlat = parseFloat(data[0].Latitude__c);
//             this.currentlang = parseFloat(data[0].Longitude__c);
//            this.updateCurrentLocationMarker();
 
//         } else {
//             console.log('OUTPUT : ', error);
//         }
//     }


//     updateCurrentLocationMarker() {
//         if (this.currentlat && this.currentlang) {
//             // Add the marker for the current location
//             this.mapMarkers = [{
//                 location: {
//                     Latitude: this.currentlat,
//                     Longitude: this.currentlang
//                 },
//                 title: 'Current Location',
//                 description: 'This is the current location'
//             }];
//             // Center the map on the current location
//             this.centerLocation = {
//                 Latitude: this.currentlat,
//                 Longitude: this.currentlang
//             };
//         }
//     }

    @api recordId;
    mapMarkers = [];
    @track centerLocation = {};
    currentlat;
    currentlang;
    isVisitRecord = false; // Variable to differentiate between records (Page type or condition)
 
    // Wire method to determine which record is being viewed
    @wire(getLocation, { recordId: '$recordId' })
    wireGetLocation({ data, error }) {
        if (data) {
            console.log('enetered into if block');
            this.isVisitRecord = false; // For getLocation record type
            this.details = data[0];
            console.log('Location Data from getLocation ---------->: ', this.details);
            
            // Safeguard: Ensure Latitude__c and Longitude__c are available
            if (data[0].Latitude__c && data[0].Longitude__c) {
                console.log('enetered into the visit location');

                this.currentlat = parseFloat(data[0].Latitude__c);
                this.currentlang = parseFloat(data[0].Longitude__c);
                this.updateCurrentLocationMarker();
            } else {
                console.error('Latitude or Longitude is missing in getLocation data.');
                this.handleLocationError();
            }
        } else {
            console.log('enetered into else block');
            console.log('Error with getLocation: ', error);
            this.handleLocationError();
        }
    }

    // Wire method to get visit location if the record type is different (for example, if it's a visit record)
    @wire(getvisitLocation, { recordId: '$recordId' })
    wireGetVisitLocation({ data, error }) {
        if (data) {
            this.isVisitRecord = true; // For visit location record type
            this.visitDetails = data[0];
            console.log('Visit Location Data from getVisitLocation ---------->: ', this.visitDetails);
            
            // Safeguard: Ensure Latitude__c and Longitude__c are available
            if (data[0].Latitude__c && data[0].Longitude__c) {
                console.log('enetered into the visit location');
                
                this.currentlat = parseFloat(data[0].Latitude__c);
                this.currentlang = parseFloat(data[0].Longitude__c);
                this.updateCurrentLocationMarker();
            } else {
                console.error('Latitude or Longitude is missing in getVisitLocation data.');
                this.handleLocationError();
            }
        } else {
            console.log('Error with getvisitLocation: ', error);
            this.handleLocationError();
        }
    }

    // Update marker and center location
    updateCurrentLocationMarker() {
        if (this.currentlat && this.currentlang) {
            this.mapMarkers = [{
                location: {
                    Latitude: this.currentlat,
                    Longitude: this.currentlang
                },
                title: this.isVisitRecord ? 'Visit Location' : 'Current Location',
                description: this.isVisitRecord ? 'This is the visit location' : 'This is the current location'
            }];
            this.centerLocation = {
                Latitude: this.currentlat,
                Longitude: this.currentlang
            };
        }
    }

    // Fallback method to handle errors
    handleLocationError() {
        // Handle errors in both wire methods, fallback logic
        this.mapMarkers = [{
            location: {
                Latitude: 0,
                Longitude: 0
            },
            title: 'Error',
            description: 'Location data could not be retrieved'
        }];
        this.centerLocation = {
            Latitude: 0,
            Longitude: 0
        };
    }
}