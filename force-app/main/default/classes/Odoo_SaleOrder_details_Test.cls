@isTest
private class Odoo_SaleOrder_details_Test {
    
    @isTest
    static void testWebhookSuccess() {
        // Mock the authentication callout response
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());

        // Simulate data for your webhook
        cgcloud__Account_Template__c testCustomerTemplate = new cgcloud__Account_Template__c(
            Name='Retailer',
            cgcloud__Description_Language_1__c='Retailer',
            cgcloud__Sales_Org__c='0001', 
            cgcloud__Active__c=true
        );
        insert testCustomerTemplate;

        Account testAccount = new Account(
            Name = 'Test Account',
            Customer_Category__c = 'R1',
            cgcloud__Account_Template__c=testCustomerTemplate.id,
            External_Id__c='12345'
        );
        insert testAccount;

        Order ord = new Order();
        ord.Name = 'Test';
        ord.EffectiveDate = Date.today();
        ord.Status = 'Draft';
        ord.AccountId = testAccount.Id;
        insert ord;

        Quote testQuote = new Quote(Name = 'Test Quote', OrderId__c = ord.Id);
        insert testQuote;

        String jsonPayload = '{"name":"Test Order", "state":"sale", "salesforce_id":"' + testQuote.Id + '"}';

        RestRequest req = new RestRequest();
        req.requestUri = '/odoo/saleorderdetail/';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonPayload);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;

        // Call the webhook handler
        Odoo_SaleOrder_details.handleWebhook();
        
        Test.stopTest();

        // Fetch the updated quote and verify status
        Quote updatedQuote = [SELECT Status FROM Quote WHERE Id = :testQuote.Id LIMIT 1];
        System.assertEquals('SalesOrder', updatedQuote.Status, 'Quote status should be updated to SalesOrder');
        System.assertEquals(200, res.statusCode, 'Response status code should be 200');
    }

    @isTest
    static void testWebhookMissingFields() {
        // Mock the authentication callout response
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());

        String jsonPayload = '{"name":"Test Order", "state":""}';

        RestRequest req = new RestRequest();
        req.requestUri = '/odoo/saleorderdetail/';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonPayload);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Odoo_SaleOrder_details.handleWebhook();
        
        Test.stopTest();

        System.assertEquals(500, res.statusCode, 'Response status code should be 500');
        System.assert(res.responseBody.toString().contains('Missing required fields'), 'Response body should indicate missing fields');
    }

    @isTest
    static void testWebhookDmlException() {
        // Mock the authentication callout response
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());

        Quote testQuote = new Quote(Name = 'Test Quote');
        insert testQuote;
        delete testQuote;

        String jsonPayload = '{"name":"Test Order", "state":"sale", "salesforce_id":"' + testQuote.Id + '"}';
        
        RestRequest req = new RestRequest();
        req.requestUri = '/odoo/saleorderdetail/';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonPayload);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Odoo_SaleOrder_details.handleWebhook();

        Test.stopTest();

        System.assertEquals(500, res.statusCode, 'Response status code should be 500');
    }

    @isTest
    static void testWebhookGeneralError() {
        // Mock the authentication callout response
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());

        String jsonPayload = '{"name":"Test Order", "state":"sale", "salesforce_id":"InvalidId"}';

        RestRequest req = new RestRequest();
        req.requestUri = '/odoo/saleorderdetail/';
        req.addHeader('Content-Type', 'application/json');
        req.requestBody = Blob.valueOf(jsonPayload);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;

        Odoo_SaleOrder_details.handleWebhook();

        Test.stopTest();

        System.assertEquals(500, res.statusCode, 'Response status code should be 500');
        System.assert(res.responseBody.toString().contains('Error processing webhook'), 'Response body should indicate general error');
    }
}