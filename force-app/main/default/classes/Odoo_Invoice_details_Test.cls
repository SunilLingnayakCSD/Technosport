@isTest
private class Odoo_Invoice_details_Test {
    @testSetup
    static void setupTestData() {
        cgcloud__Account_Template__c testCustomerTemplate = new cgcloud__Account_Template__c(
            Name='Retailer',
            cgcloud__Description_Language_1__c='Retailer',
            cgcloud__Sales_Org__c='0001', 
            cgcloud__Active__c=true
        );
        insert testCustomerTemplate;



        // Create an account with Customer_Category__c = 'R1'
        Account testAccount = new Account(

            Name = 'Test Account',
            Customer_Category__c = 'R1', // Must match getPricebookdetails logic
            cgcloud__Account_Template__c=testCustomerTemplate.id,
            BillingPostalCode='273747',BillingCity='xys',BillingStreet='Karnataka'
            
        );
        insert testAccount;
        
        
        // Create a test Quote
        Quote testQuote = new Quote(Name = 'Test Quote', OrderId__c = null);
        insert testQuote;

        // Create a test Order
        Order testOrder = new Order(Name = 'Test Order', Status = 'Draft',AccountId=testAccount.id,EffectiveDate = Date.newInstance(2025, 2, 6));
        insert testOrder;
        
        // Update the quote with order Id
        testQuote.OrderId__c = testOrder.Id;
        update testQuote;
    }

    @isTest
    static void testHandleWebhookSuccess() {
        // Prepare mock JSON request body
        String requestBody = '{"name": "Test Invoice", "local_transporter": "XYZ Logistics", "lr_date": "2024-01-01", "lr_no": "LR12345", "id": 1001, "partner_id": "12345", "invoice_date_due": "2024-02-01", "invoice_date": "2024-01-15", "partner_shipping_id": "ShippingAddress1", "journal_id": "JRN001", "salesforce_id": "' + [SELECT Id FROM Quote LIMIT 1].Id + '", "amount_paid": 500.00, "amount_total_words": "Five Hundred Only", "ref": "INV-001"}';
        Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());
        Test.startTest();
        
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        Odoo_Invoice_details.handleWebhook();
        Test.stopTest();

        // Validate that the Invoice record was created
        Invoice__c createdInvoice = [SELECT Id, Name, Amount__c FROM Invoice__c WHERE Name = 'Test Invoice' LIMIT 1];
        System.assertNotEquals(null, createdInvoice, 'Invoice should be created');
        System.assertEquals(500.00, createdInvoice.Amount__c, 'Amount should match the payload');
    }

    @isTest
    static void testHandleWebhookMissingInvoiceDateDue() {
        // Prepare mock JSON request body with missing invoice_date_due
        String requestBody = '{"name": "Test Invoice", "id": 1002}';
        Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());
        Test.startTest();
        
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        try {
            Odoo_Invoice_details.handleWebhook();
            
        } catch (Odoo_Invoice_details.CustomException e) {
            System.assertEquals('Missing required field: invoice_date_due', e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testHandleWebhookNoAccountFound() {
        // Prepare mock JSON request body with a non-existing partner_id
        String requestBody = '{"name": "Test Invoice", "id": 1003, "partner_id": "99999", "invoice_date_due": "2024-02-01"}';
         Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());
        Test.startTest();
       
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Odoo_Invoice_details.handleWebhook();
        Test.stopTest();

        // Validate that invoice is created without an Account__c
        Invoice__c createdInvoice = [SELECT Id, Name, Account__c FROM Invoice__c WHERE Name = 'Test Invoice' LIMIT 1];
        System.assertNotEquals(null, createdInvoice, 'Invoice should be created');
       // System.assertEquals(null, createdInvoice.Account__c, 'Account__c should be null');
    }

    @isTest
    static void testHandleWebhookDMLException() {
        // Prepare mock JSON request body with missing Name (which is required)
        String requestBody = '{"id": 1004, "invoice_date_due": "2024-02-01"}';
         Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());
        Test.startTest();
       
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(requestBody);
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Odoo_Invoice_details.handleWebhook();
        Test.stopTest();

        // Check that response contains error message
        System.assert(RestContext.response.statusCode == 500, 'Response should return 500 error');
        System.assert(RestContext.response.responseBody.toString().contains('Invoice Name cannot be null'), 'Expected error for missing Name');
    }
}