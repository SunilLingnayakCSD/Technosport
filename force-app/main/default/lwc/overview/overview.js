import { LightningElement,api,track,wire } from 'lwc';
import getUserProfileImage from '@salesforce/apex/ProductController.getAccountsForLoggedInUser'
import userCounts from '@salesforce/apex/ProductController.userCounts'
import USER_Id from '@salesforce/user/Id';
import img1 from '@salesforce/resourceUrl/img1'
import DownArrow from '@salesforce/resourceUrl/DownArrow';
import Salesperformance from '@salesforce/resourceUrl/Salesperformance'
import LeadAssigned from '@salesforce/resourceUrl/LeadAssigned'
import CaseAnalytics from '@salesforce/resourceUrl/CaseAnalytics'

import { getRecord } from 'lightning/uiRecordApi';


import USER_FIELD from '@salesforce/schema/User.SmallPhotoUrl';
import username from '@salesforce/schema/User.Name';
import email from '@salesforce/schema/User.Email';
import phone from '@salesforce/schema/User.Phone';
import Street from '@salesforce/schema/User.Street';
import City from '@salesforce/schema/User.City';
import State from '@salesforce/schema/User.State';
import PostalCode from '@salesforce/schema/User.PostalCode';
import Country from '@salesforce/schema/User.Country';
import Username  from '@salesforce/schema/User.Username';
export default class Overview extends LightningElement {  
    @track userId=USER_Id;
    @track userPhotoUrl;
    Salesperformance=Salesperformance 
    LeadAssigned=LeadAssigned
    CaseAnalytics=CaseAnalytics
    img1=img1
    DownArrow = DownArrow;
    @track name;
    @track accounts;
    @track error; 
    @track username;
    @track userEmail;
    @track userPhone;
    @track userStreet;
    @track userCity;
    @track userState;
    @track userCountry;
    @track userPostal;
    @track usernameofuser

    @wire(getRecord, { recordId: USER_Id, fields: [USER_FIELD,username,email,phone,Street,City,State,PostalCode,Country,Username ] })
    userRecord({ error, data }) {
        if (data) {
            console.log('==================== Data ==================');
            console.log(data);
            const smallPhotoUrl = data.fields.SmallPhotoUrl.value
            this.username = data.fields.Name.value
            this.userEmail = data.fields.Email.value
            this.userPhone = data.fields.Phone.value
            this.userState = data.fields.State.value
            this.userCity = data.fields.City.value
            this.userStreet = data.fields.Street.value
            this.userCountry = data.fields.Country.value
            this.userPostal = data.fields.PostalCode.value
            this.usernameofuser = data.fields.Username.value
            const instanceUrl = window.location.origin; 
            this.userPhotoUrl = `${instanceUrl}${smallPhotoUrl}`;
            console.log('============== this.userPhotoUrl======================');
            console.log( this.userPhotoUrl);
            
        } else if (error) {
            console.log('====================================');
            console.log(error);
            console.log('====================================');
        }
    }

    // connectedCallback(){
    //     console.log(this.fetchUserProfileImage());
        
    // }
    renderedCallback() {
        this.initializeAccordion(); 
        
       
    }
    @track acc;
    connectedCallback() {
        userCounts({ recordId: this.userId })
            .then(result => {
                if (result && result.length > 0) {
                    this.accounts =result;
                    console.log('==================this.accounts[0]==================');
                    console.log(result[0]);
                    console.log('====================================');
                    this.acc=result[0]
                    console.log('Accounts fetched:', JSON.stringify(this.accounts, null, 2));
                    console.log('Accounts fetched-------------------:', JSON.stringify(this.acc));
                } else {
                    console.log('No accounts found for the logged-in user.');
                }
            })
            .catch(error => {
                this.error = error;
                console.error('Error fetching accounts:', error);
            });
    }

    // fetchUserProfileImage() {
    //     getUserProfileImage({userId:this.userId})
    //         .then((result) => {
    //             console.log('User Photo URL:', result);
    //             this.userPhotoUrl = result;
    //             console.log('===============userPhotoUrl=====================');
    //             console.log(JSON.stringify(this.userPhotoUrl,null,2));
    //             console.log('====================================');
                
    //         })
    //         .catch((error) => {
    //             console.error('Error fetching user photo URL:', error);
    //         });
    // }
    
    
    initializeAccordion() {
        const acc = this.template.querySelectorAll('.accordion');
        
        acc.forEach((element) => {
            element.addEventListener('click', () => {
                element.classList.toggle('active');
                
                const panel = element.nextElementSibling;
                
                if (panel) {
                    if (panel.style.display === 'block') {
                        panel.style.display = 'none';
                    } else {
                        panel.style.display = 'block';
                    }
                }
            });
        });
    }
    
    


    // connectedCallback() {
    //     this.fetchAccounts();
    // }
   

    // fetchAccounts() {
    //     console.log('sending to apex');
    //     console.log('sending record id',this.userId);
        
        
    //     userCounts({ recordId: this.userId })
    // .then((result) => {
    //     console.log('Returned result:', result); // Logs the result from Apex
        
    //     // Check if the result is an array and has items
    //     if (Array.isArray(result) && result.length > 0) {
    //         this.accounts = result;
    //         console.log('Accounts fetched:', JSON.stringify(this.accounts, null, 2));
    //     } else {
    //         console.log('No accounts found for the logged-in user.');
    //     }
    // })
    // .catch((error) => {
    //     this.error = error; // Capture and store the error
    //     console.error('Error fetching accounts:', JSON.stringify(error, null, 2));
    // });

    
    // }

   
}