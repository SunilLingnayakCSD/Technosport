import { LightningElement,track,api,wire } from 'lwc';
import getvisitLocation from '@salesforce/apex/invoicepopupController.getvisitLocation'


export default class VisitMapController extends LightningElement {
       @api recordId;
    mapMarkers = [];
    @track centerLocation = {};
    currentlat;
    currentlang;
     
        @wire(getvisitLocation, { recordId: '$recordId' })
        wireGetrecords({ data, error }) {
            if (data) {
                this.details = data[0];
                console.log('OUTPUT ---------->: ', this.details);
                this.currentlat = parseFloat(data[0].Latitude__c);
                this.currentlang = parseFloat(data[0].Longitude__c);
               this.updateCurrentLocationMarker();
     
            } else {
                console.log('OUTPUT : ', error);
            }
        }
    
    
        updateCurrentLocationMarker() {
            if (this.currentlat && this.currentlang) {
                // Add the marker for the current location
                this.mapMarkers = [{
                    location: {
                        Latitude: this.currentlat,
                        Longitude: this.currentlang
                    },
                    title: 'Current Location',
                    description: 'This is the current location'
                }];
                // Center the map on the current location
                this.centerLocation = {
                    Latitude: this.currentlat,
                    Longitude: this.currentlang
                };
            }
        }
}