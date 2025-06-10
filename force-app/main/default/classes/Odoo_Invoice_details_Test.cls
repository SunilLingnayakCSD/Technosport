@isTest
private class Odoo_Invoice_details_Test {

    @isTest
    static void testWebhookSuccess() {
        // Mock the authentication callout response
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());

        // Create test data
        Account testAccount = new Account(
            Name = 'Test Account',
            External_Id__c = '12345',
            ShippingStreet = '123 Test St',
            ShippingCity = 'Test City',
            ShippingState = 'Test State',
            ShippingPostalCode = '12345',
            ShippingCountry = 'Test Country'
        );
        insert testAccount;

        Order testOrder = new Order(
            Name = 'Test Order',
            Status = 'Draft',
            AccountId = testAccount.Id,
            EffectiveDate = System.today()
        );
        insert testOrder;

        Quote testQuote = new Quote(
            Name = 'Test Quote',
            Status = 'Draft',
            OrderId__c = testOrder.Id
        );
        insert testQuote;

        // Prepare JSON payload for the webhook
        String jsonPayload = '{"name":"Test Invoice", "local_transporter":"Test Transporter", "lr_date":"2025-03-21", "lr_no":"LR12345", "id":123, "partner_id":"12345", "invoice_date_due":"2025-04-21", "invoice_date":"2025-03-21", "partner_shipping_id":"Test Shipping Address", "salesforce_id":"' + testQuote.Id + '", "amount_paid":1000.00, "amount_total_words":"One Thousand", "ref":"REF12345", "amount_residual":500.00}';

        // Set up the REST request
        RestRequest req = new RestRequest();
        req.requestUri = '/odoo/invoicedetail/';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonPayload);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Call the webhook handler
        Odoo_Invoice_details.handleWebhook();
        
        Test.stopTest();

        // Verify the results
        Invoice__c insertedInvoice = [SELECT Name, Transporter_Name__c, LR_Date__c, LR_No__c, Invoice_Id__c, Account__c, Due_Date__c, Invoice_Date__c, Delivery_Address__c, Amount_in_Words__c, Amount__c, Reference__c, Residual_Amount__c FROM Invoice__c WHERE Name = 'Test Invoice' LIMIT 1];
        System.assertNotEquals(null, insertedInvoice, 'Invoice should be inserted');
        System.assertEquals('Test Invoice', insertedInvoice.Name);
        System.assertEquals('Test Transporter', insertedInvoice.Transporter_Name__c);
      //  System.assertEquals(System.today(), insertedInvoice.LR_Date__c);
        System.assertEquals('LR12345', insertedInvoice.LR_No__c);
        System.assertEquals('123', insertedInvoice.Invoice_Id__c);
      //  System.assertEquals(System.today().addDays(30), insertedInvoice.Due_Date__c);
        //System.assertEquals(System.today(), insertedInvoice.Invoice_Date__c);
        System.assertEquals('Test Shipping Address', insertedInvoice.Delivery_Address__c);
        System.assertEquals('One Thousand', insertedInvoice.Amount_in_Words__c);
        System.assertEquals(1000.00, insertedInvoice.Amount__c);
        System.assertEquals('REF12345', insertedInvoice.Reference__c);
        System.assertEquals(500.00, insertedInvoice.Residual_Amount__c);

        // Verify the Quote and Order statuses were updated
        Quote updatedQuote = [SELECT Status FROM Quote WHERE Id = :testQuote.Id LIMIT 1];
     //   System.assertEquals('Invoice', updatedQuote.Status, 'Quote status should be updated to Invoice');

        Order updatedOrder = [SELECT Status FROM Order WHERE Id = :testOrder.Id LIMIT 1];
      //  System.assertEquals('Invoice', updatedOrder.Status, 'Order status should be updated to Invoice');
    }

    @isTest
    static void testWebhookMissingRequiredField() {
        // Mock the authentication callout response
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());

        // Prepare test data with missing required field (invoice_date_due)
        String jsonPayload = '{"name":"Test Invoice", "local_transporter":"Test Transporter", "lr_date":"2025-03-21", "lr_no":"LR12345", "id":123, "partner_id":"12345", "invoice_date":"2025-03-21", "partner_shipping_id":"Test Shipping Address", "salesforce_id":"12345", "amount_paid":1000.00, "amount_total_words":"One Thousand", "ref":"REF12345", "amount_residual":500.00}';

        // Set up the REST request
        RestRequest req = new RestRequest();
        req.requestUri = '/odoo/invoicedetail/';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonPayload);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Call the webhook handler
        Odoo_Invoice_details.handleWebhook();
        
        Test.stopTest();

        // Verify the response
        System.assertEquals(500, res.statusCode, 'Response status code should be 500');
        System.assert(res.responseBody.toString().contains('Missing required field: invoice_date_due'), 'Response body should contain missing field error');
    }

    @isTest
    static void testWebhookDmlException() {
        // Mock the authentication callout response
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());

        // Create a Quote and delete it to simulate DML exception
        Quote testQuote = new Quote(Name = 'Test Quote');
        insert testQuote;
        delete testQuote;

        // Prepare JSON payload for the webhook
        String jsonPayload = '{"name":"Test Invoice", "local_transporter":"Test Transporter", "lr_date":"2025-03-21", "lr_no":"LR12345", "id":123, "partner_id":"12345", "invoice_date_due":"2025-04-21", "invoice_date":"2025-03-21", "partner_shipping_id":"Test Shipping Address", "salesforce_id":"' + testQuote.Id + '", "amount_paid":1000.00, "amount_total_words":"One Thousand", "ref":"REF12345", "amount_residual":500.00}';

        // Set up the REST request
        RestRequest req = new RestRequest();
        req.requestUri = '/odoo/invoicedetail/';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonPayload);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Call the webhook handler
        Odoo_Invoice_details.handleWebhook();
        
        Test.stopTest();

        // Verify the response
        System.assertEquals(500, res.statusCode, 'Response status code should be 500');
        //System.assert(res.responseBody.toString().contains('DML Error'), 'Response body should contain DML error');
    }

    @isTest
    static void testWebhookGeneralError() {
        // Mock the authentication callout response
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());

        // Prepare JSON payload for the webhook with invalid salesforce_id
        String jsonPayload = '{"name":"Test Invoice", "local_transporter":"Test Transporter", "lr_date":"2025-03-21", "lr_no":"LR12345", "id":123, "partner_id":"12345", "invoice_date_due":"2025-04-21", "invoice_date":"2025-03-21", "partner_shipping_id":"Test Shipping Address", "salesforce_id":"InvalidId", "amount_paid":1000.00, "amount_total_words":"One Thousand", "ref":"REF12345", "amount_residual":500.00}';

        // Set up the REST request
        RestRequest req = new RestRequest();
        req.requestUri = '/odoo/invoicedetail/';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonPayload);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Call the webhook handler
        Odoo_Invoice_details.handleWebhook();
        
        Test.stopTest();

        // Verify the response
        System.assertEquals(500, res.statusCode, 'Response status code should be 500');
        System.assert(res.responseBody.toString().contains('Error processing webhook'), 'Response body should indicate general error');
    }
}