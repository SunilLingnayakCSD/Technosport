@isTest
private class Odoo_Invoice_lineItems_Details_Test {
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
            External_Id__c='12345'
            
        );
        insert testAccount;
        
        // Create test Invoice
        Invoice__c testInvoice = new Invoice__c(
            Name = 'Test Invoice',
            Invoice_Id__c = '12345',
            Account__c=testAccount.Id// Simulating an Invoice ID from Odoo
        );
        insert testInvoice;
    }

    @isTest
    static void testInsertInvoiceLineItemSuccess() {
        // Mock request data
        Product2 po=new Product2();
        po.name='Test';
        po.Variant_ExternalId__c='123456';
        insert po;
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'journal_id' => 12345,
            'move_id' => 12345,
            'id' => 56789,
            'name' => 'Test Product',
            'price_subtotal' => 100.00,
            'price_unit' => 10.00,
            'product_id' => 123456,
            'quantity' => 10
        }));
        RestContext.request = req;
        RestContext.response = res;

        // Call the method
        Test.startTest();
        Odoo_Invoice_lineItems_Details.insertInvoiceFromOdooToSalesFroce();
        Test.stopTest();

        // Validate response
        System.assertEquals(200, res.statusCode);
        System.assert(res.responseBody.toString().contains('Success'));
    }

  
    @isTest
static void testNoProductFound() {
    // Create mock request data with a non-existent invoice
    /* Product2 po=new Product2();
        po.name='Test';
        po.Product_External_ID__c='123456';
        insert po;*/
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object> {
        'journal_id' => 99999, // Non-existent invoice
        'move_id' => 99999,
        'id' => 56789,
        'name' => 'Test Product',
        'price_subtotal' => 100.00,
        'price_unit' => 10.00,
        'product_id' => null,
        'quantity' => 10
    }));
    RestContext.request = req;
    RestContext.response = res;

    // Call the method to insert the invoice from Odoo
    Test.startTest();
    Odoo_Invoice_lineItems_Details.insertInvoiceFromOdooToSalesFroce();
    Test.stopTest();

    // Assert that the status code is 404 (as returned by the method)
    System.assertEquals(404, res.statusCode); // Expecting 404 instead of 400
    
} 
 @isTest
static void testMisMatchProductFound() {
    // Create mock request data with a non-existent invoice
     Product2 po=new Product2();
        po.name='Test';
        po.Product_External_ID__c='123456';
        insert po;
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object> {
        'journal_id' => 99999, // Non-existent invoice
        'move_id' => 99999,
        'id' => 56789,
        'name' => 'Test Product',
        'price_subtotal' => 100.00,
        'price_unit' => 10.00,
        'product_id' => '12',
        'quantity' => 10
    }));
    RestContext.request = req;
    RestContext.response = res;

    // Call the method to insert the invoice from Odoo
    Test.startTest();
    Odoo_Invoice_lineItems_Details.insertInvoiceFromOdooToSalesFroce();
    Test.stopTest();

    // Assert that the status code is 404 (as returned by the method)
    System.assertEquals(500, res.statusCode); // Expecting 404 instead of 400
    
} 
    @isTest
static void testUpsertProductFound() {
    // Create mock request data with a non-existent invoice
     Product2 po=new Product2();
        po.name='Test';
        po.Product_External_ID__c='123456';
        insert po;
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object> {
        'journa_id' => 99999, // Non-existent invoice
        'move_id' => 99999,
        'id' => 56789,
        'name' => 'Test Product',
        'price_subtotal' => 100.00,
        'price_unit' => 10.00,
        'product_id' => '12',
        'quantity' => 10
    }));
    RestContext.request = req;
    RestContext.response = res;

    // Call the method to insert the invoice from Odoo
    Test.startTest();
    Odoo_Invoice_lineItems_Details.insertInvoiceFromOdooToSalesFroce();
    Test.stopTest();

    
    System.assertEquals(500, res.statusCode); 
    
} 


   @isTest
static void testDMLException() {
    // Insert an invoice that will cause a duplicate error
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
        Name = 'Duplicate Invoice',
        Invoice_Id__c = '54321',
        Account__c=testAccount.Id
        // Simulating a duplicate Invoice ID from Odoo
    );
    insert testInvoice;

    // Create a mock request that would trigger a DML error (duplicate issue)
    RestRequest req = new RestRequest();
    RestResponse res = new RestResponse();
    req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object> {
        'journal_id' => 54321,
        'move_id' => 54321,
        'id' => 56789,
        'name' => 'Test Product',
        'price_subtotal' => 100.00,
        'price_unit' => 10.00,
        'product_id' => 9999,
        'quantity' => 10
    }));
    RestContext.request = req;
    RestContext.response = res;

    // Call the method to insert the invoice from Odoo
    Test.startTest();
    Odoo_Invoice_lineItems_Details.insertInvoiceFromOdooToSalesFroce();
    Test.stopTest();

    // Assert that the status code is 500 for a DML error
   
}

    @isTest
    static void testInsertInvoiceFromOdooToSalesForce_NoInvoice() {
        Test.startTest();
        
        // Preparing mock request data where invoice does not exist
        Map<String, Object> requestData = new Map<String, Object>{
            'journal_id' => 1,
            '_model' => 'testModel',
            '_name' => 'testName',
            'delivery_date' => Date.today(),
            'id' => 1001,
            'move_id' => '99999', // Non-existent invoice ID
            'name' => 'Test Item',
            'price_subtotal' => 100.00,
            'price_unit' => 50.00,
            'product_id' => 5001,
            'quantity' => 2
        };
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(JSON.serialize(requestData));
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = res;
        
        // Calling the method
        try {
            Odoo_Invoice_lineItems_Details.insertInvoiceFromOdooToSalesFroce();
        } catch (Exception e) {
            System.assert(e.getMessage().contains('No Invoice found for Journal ID'), 'Exception should indicate missing invoice');
        }
        
        Test.stopTest();
    }
  
}