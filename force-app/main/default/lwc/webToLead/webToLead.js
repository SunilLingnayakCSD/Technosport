import { LightningElement, track } from 'lwc';
import insertLead from '@salesforce/apex/webToLead.insertLead';
import ftdinfocompng from '@salesforce/resourceUrl/Technologo';
import LightningAlert from 'lightning/alert';
 
export default class WebToLead extends LightningElement {
    @track showThankYouMessage = false;
    ftdinfocompng = ftdinfocompng;
 
    // Track the field values
    @track Name = '';
    @track phoneNo = '';
    @track emailId = '';
    @track RetailerOrWholesaler = '';
    @track GST = '';
    @track SoldTechnoSport = '';
    @track City = '';
    @track Pincode = '';
    @track StoreCategory = '';
    @track Walkins = '';
    @track Brands = [];
    @track OwnStore = '';
    @track Company = '';
    @track UniformCategory = '';
 
    // Store error messages for each field
    @track fieldErrors = {
        Name: '',
        Phone: '',
        Email: '',
        City: '',
        Pincode: '',
        StoreName:'',
        StoreCategory: '',
    };
      @track duplicateFieldErrors = {
         phone :'',
         Email :'',
 
      }
    // Store Category Options
    StoreCategoryOptions = [
        { label: 'Men\'s Wear', value: 'Men\'s Wear' },
        { label: 'Family Readymade Shop', value: 'Family Readymade Shop' },
        { label: 'Multi-Department Store', value: 'Multi-Department Store' },
        { label: 'Sport Goods Store', value: 'Sport Goods Store' },
        { label: 'Uniform (NCC, Police, School Uniforms)', value: 'Uniform (NCC, Police, School Uniforms)' },
        { label: 'Printer Shop', value: 'Printer Shop' },
        { label: 'Corporate Order Supplier', value: 'Corporate Order Supplier' },
    ];
 
    SoldTechnoSportOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' },
    ];
 
    RetailerWholesalerOptions = [
        { label: 'Retailer', value: 'Retailer' },
        { label: 'Wholesaler', value: 'Wholesaler' },
    ];
 
    OwnStoreOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' },
    ];
 
    GSTOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' },
    ];
 
    // Additional Options
    WalkinOptions = [
        { label: '10-20 customers', value: '10-20 customers' },
        { label: '20-50 customers', value: '20-50 customers' },
        { label: '50-100 customers', value: '50-100 customers' },
        { label: 'More than 100 customers', value: 'More than 100 customers' },
    ];
 
    BrandOptions = [
        { label: 'Jockey', value: 'Jockey' },
        { label: 'Dixcy', value: 'Dixcy' },
        { label: 'Lux/Actimaxx/Onn', value: 'Lux/Actimaxx/Onn' },
        { label: 'Yonex', value: 'Yonex' },
        { label: 'Shiv Naresh', value: 'Shiv Naresh' },
        { label: 'Fitrex', value: 'Fitrex' },
        { label: 'Nivia', value: 'Nivia' },
        { label: 'Dazzle', value: 'Dazzle' },
        { label: 'Others', value: 'Others' },
    ];
 
    // Validation method to check if all required fields are filled
validateForm() {
    console.log('validating fields');
    let isValid = true;
    this.fieldErrors = {};  

    // Check Name field
    const nameInput = this.template.querySelector('.Name');
    let nameInputVal = nameInput ? nameInput.value : '';
    if (!nameInputVal) {
        nameInput.setCustomValidity('Please enter the name');
        isValid = false;
    } else {
        nameInput.setCustomValidity('');
    }
    nameInput.reportValidity();

    // Check Phone field
    const phoneInput = this.template.querySelector('.Phone');
    let phoneInputVal = phoneInput ? phoneInput.value : '';
    if (!phoneInputVal) {
        phoneInput.setCustomValidity('Please enter the phone number');
        isValid = false;
    } else {
        phoneInput.setCustomValidity('');
    }
    phoneInput.reportValidity();

    // Check Email field
    const emailInput = this.template.querySelector('.Email');
    let emailInputVal = emailInput ? emailInput.value : '';
    if (!emailInputVal) {
        emailInput.setCustomValidity('Please enter the email address');
        isValid = false;
    } else {
        emailInput.setCustomValidity('');
    }
    emailInput.reportValidity();

    // Check City field
    const cityInput = this.template.querySelector('.City');
    let cityInputVal = cityInput ? cityInput.value : '';
    if (!cityInputVal) {
        cityInput.setCustomValidity('Please enter the city');
        isValid = false;
    } else {
        cityInput.setCustomValidity('');
    }
    cityInput.reportValidity();

    // Check Pincode field
    const pincodeInput = this.template.querySelector('.Pincode');
    let pincodeInputVal = pincodeInput ? pincodeInput.value : '';
    if (!pincodeInputVal) {
        pincodeInput.setCustomValidity('Please enter the pincode');
        isValid = false;
    } else {
        pincodeInput.setCustomValidity('');
    }
    pincodeInput.reportValidity();

    // Check Store Name field
    const storeNameInput = this.template.querySelector('.StoreName');
    let storeNameInputVal = storeNameInput ? storeNameInput.value : '';
    if (!storeNameInputVal) {
        storeNameInput.setCustomValidity('Please enter the store name');
        isValid = false;
    } else {
        storeNameInput.setCustomValidity('');
    }
    storeNameInput.reportValidity();

    // Check Store Category field
    const storeCategoryInput = this.template.querySelector('.StoreCategory');
    let storeCategoryVal = storeCategoryInput ? storeCategoryInput.value : '';
    if (!storeCategoryVal) {
        storeCategoryInput.setCustomValidity('Please select the store category');
        isValid = false;
    } else {
        storeCategoryInput.setCustomValidity('');
    }
    storeCategoryInput.reportValidity();

    return isValid;
}

 
  validateDuplicates() {
    let isValid = true;
  // Check Phone field
        const phone = this.template.querySelector('.Phone');
        if (phone) {
           
           phone.setCustomValidity('This phone number already exists in our records. Please provide a different phone number.');
            isValid = false;
        } else {
           phone.setCustomValidity('');
        }
        phone.reportValidity();
 
        // Check Email field
        const email = this.template.querySelector('.Email');
        if (!email) {
         
            email.setCustomValidity('This Email already exists in our records. Please provide a different Email.');
            isValid = false;
        } else {
              email.setCustomValidity('');
        }
          email.reportValidity();
         return isValid;  
 
  }
    LeadChangeVal(event) {
        const { name, value } = event.target;
 
        if (name === 'Name') {
            this.Name = value;
        } else if (name === 'Phone') {
            this.phoneNo = value;
        } else if (name === 'Email') {
            this.emailId = value;
        } else if (name === 'StoreCategory') {
            this.StoreCategory = value;
        } else if (name === 'City') {
            this.City = value;
        } else if (name === 'UniformCategory') {
            this.UniformCategory = value;
        } else if (name === 'RetailerOrWholesaler') {
            this.RetailerOrWholesaler = value;
        } else if (name === 'GST') {
            this.GST = value;
        } else if (name === 'OwnStore') {
            this.OwnStore = value;
        } else if (name === 'Pincode') {
            this.Pincode = value;
        } else if (name === 'Walkins') {
            this.Walkins = value;
        } else if (name === 'Company') {
            this.Company = value;
        } else if (name === 'Brands') {
            this.Brands = value;
        } else if (name === 'LeadStatus') {  // New field
            this.LeadStatus = value;
        }
    }
 
 handleSubmit() {
    this.error = '';
    this.isLeadSubmitted = false;

    // Check if the form is valid (if not, prevent submission)
    if (!this.validateForm()) {
        console.log('Form is not valid');
        return;  // Prevent form submission if validation fails
    }
    
    // Proceed to submit the lead if form is valid
    console.log('Form Valid');
    this.insertLeadAction();
    console.log('Lead Inserted');
}

 
    insertLeadAction() {
 
        console.log('Preparing to insert lead with following data:');
   
 
        const leadObj = {
            sobjectType: 'Lead__c',
            Name: this.Name,
            Phone__c: this.phoneNo,
            Email__c: this.emailId,
            Address__City__s: this.City,
            Address__PostalCode__s: this.Pincode,
            Category_of_store_you_are_dealing_with__c: this.StoreCategory,
            Average_walking_s_per_day__c: this.Walkins,
            Are_you_a_retailer_or_wholesale__c: this.RetailerOrWholesaler,
            Brand_you_are_handling_currently__c: this.Brands.join(', '),
            Do_you_have_a_GST__c: this.GST,
            Do_you_own_a_Store__c: this.OwnStore,
            Have_you_sold_Technosport_products_befor__c: this.SoldTechnoSport,
            Company__c: this.Company,
           Select_Uniform_Type__c: this.UniformCategory,
        };
 
 console.log('Name:', this.Name);
    console.log('Phone:', this.phoneNo);
    console.log('Email:', this.emailId);
    console.log('City:', this.City);
    console.log('Pincode:', this.Pincode);
    console.log('StoreCategory:', this.StoreCategory);
    console.log('Walkins:', this.Walkins);
    console.log('RetailerOrWholesaler:', this.RetailerOrWholesaler);
    console.log('Brands:', this.Brands);
    console.log('GST:', this.GST);
    console.log('OwnStore:', this.OwnStore);
    console.log('SoldTechnoSport:', this.SoldTechnoSport);
    console.log('Company:', this.Company);
    console.log('UniformCategory:', this.UniformCategory);
   
        insertLead({ obj: leadObj })
            .then(response => {
                console.log('leadObj:', leadObj);
                  console.log('Response from Apex:', JSON.stringify(response));
                   console.log('response.status :', response.status );
                   console.log('Message:', response.message);
                if (response.status === 'duplicate') {
                      console.log('responseMessage:', response.message);
                    if (response.message.includes('Duplicate lead detected')) {
                        LightningAlert.open({
                            message: 'Duplicate detected: The phone or email you entered already exists in the system',
                            theme: 'error',
                            label: 'Error!',
                        });
                    }
                    // if (response.message.includes('Email')) {
                       
                    //     LightningAlert.open({
                    //         message: 'Duplicate email found: ' + response.message,
                    //         theme: 'error',
                    //         label: 'Error!',
                    //     });
                    // }
                } else if (response.status === 'success') {
                    this.showThankYouMessage = true;
                     console.log('this.showThankYouMessage :', this.showThankYouMessage );
                    this.isLeadSubmitted = true;
                     console.log(' this.isLeadSubmitted:',  this.isLeadSubmitted);
                }
            })
            .catch(error => {
                console.error('Error in lead submission:', error);
                this.error = 'Error inserting lead: ' + error.body.message;
                LightningAlert.open({
                    message: 'Error inserting lead: ' + error.body.message,
                    theme: 'error',
                    label: 'Error!',
                });
            });
    }
}