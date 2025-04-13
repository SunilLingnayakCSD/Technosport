@isTest
public class Odoo_Invoice_update_Residual_Amount_Test {

    @isTest
    static void testUpdateResidualAmount_Success() {
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
            External_Id__c='12345'
            
        );
        insert testAccount;
        Invoice__c testInvoice = new Invoice__c(
            Name = 'Test Invoice',
            Invoice_Id__c = '12345',
            Residual_Amount__c = 100.00,
            Account__c=testAccount.Id
        );
        insert testInvoice;

        // Prepare the request body
        String requestBody = '{"id": 12345, "amount_residual": 50.00}';
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(requestBody);
        RestContext.request = request;

        // Initialize RestContext.response
        RestResponse response = new RestResponse();
        RestContext.response = response;

        // Call the method to test
        Test.startTest();
        Odoo_Invoice_update_Residual_Amount.updateResidualAmount();
        Test.stopTest();

        // Verify the results
        Invoice__c updatedInvoice = [SELECT Id, Residual_Amount__c FROM Invoice__c WHERE Id = :testInvoice.Id];
        System.assertEquals(50.00, updatedInvoice.Residual_Amount__c, 'Residual amount should be updated to 50.00');

        // Verify the response
        System.assertEquals(200, RestContext.response.statusCode, 'Status code should be 200');
        System.assertEquals('Webhook processed and Invoice record updated successfully', RestContext.response.responseBody.toString(), 'Response body should indicate success');
    }

    @isTest
    static void testUpdateResidualAmount_InvoiceNotFound() {
        // Prepare the request body with an ID that does not exist
        String requestBody = '{"id": 99999, "amount_residual": 50.00}';
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(requestBody);
        RestContext.request = request;

        // Initialize RestContext.response
        RestResponse response = new RestResponse();
        RestContext.response = response;

        // Call the method to test
        Test.startTest();
        Odoo_Invoice_update_Residual_Amount.updateResidualAmount();
        Test.stopTest();

        // Verify the response
       // System.assertEquals(500, RestContext.response.statusCode, 'Status code should be 500');
       // System.assertEquals('Webhook processed and Invoice record Not Found', RestContext.response.responseBody.toString(), 'Response body should indicate invoice not found');
    }

    @isTest
    static void testUpdateResidualAmount_Exception() {
        // Prepare the request body with invalid JSON to trigger an exception
        String requestBody = 'invalid JSON';
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(requestBody);
        RestContext.request = request;

        // Initialize RestContext.response
        RestResponse response = new RestResponse();
        RestContext.response = response;

        // Call the method to test
        Test.startTest();
        Odoo_Invoice_update_Residual_Amount.updateResidualAmount();
        Test.stopTest();

        // Verify the response
        System.assertEquals(500, RestContext.response.statusCode, 'Status code should be 500');
        System.assert(RestContext.response.responseBody.toString().startsWith('Error processing webhook:'), 'Response body should indicate an error occurred');
    }

    @isTest
    static void testUpdateResidualAmount_DMLException() {
        // Create test data
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
            External_Id__c='12345'
            
        );
        insert testAccount;
        Invoice__c testInvoice = new Invoice__c(
            Name = 'Test Invoice',
            Invoice_Id__c = '12345',
            Residual_Amount__c = 100.00,
            Account__c=testAccount.Id
        );
        insert testInvoice;

        // Prepare the request body
        String requestBody = '{"id": 12345, "amount_residual": 50.00}';
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(requestBody);
        RestContext.request = request;

        // Initialize RestContext.response
        RestResponse response = new RestResponse();
        RestContext.response = response;

        // Force a DML exception by deleting the invoice before the update
        delete testInvoice;

        // Call the method to test
        Test.startTest();
        Odoo_Invoice_update_Residual_Amount.updateResidualAmount();
        Test.stopTest();

        // Verify the response
       // System.assertEquals(500, RestContext.response.statusCode, 'Status code should be 500');
       // System.assert(RestContext.response.responseBody.toString().startsWith('DML Error:'), 'Response body should indicate a DML error occurred');
    }
}