@isTest
private class Odoo_Inventory_items_Test {
    @testSetup
    static void setupTestData() {
        
        cgcloud__Product_Template__c ProductTemplatetest= new cgcloud__Product_Template__c(
            Name ='Test Product template',
            cgcloud__Sales_Org__c='0001',
            cgcloud__Description_Language_1__c	='Test Product template',
            cgcloud__Active__c=true
            
            
        );
        insert ProductTemplatetest;
       // Create a product with required fields
        Id productRecTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true,
            Image_url__c = 'test.jpg',
            RecordTypeId = productRecTypeId,
            Product_Category__c = 'Men', // Ensure this matches getProducts filters
            cgcloud__Category__c = 'ALL', // Ensure this matches getProducts filters
            cgcloud__Product_Template__c=ProductTemplatetest.id,
            cgcloud__Product_Level__c='Product',
            cgcloud__Description_1_Language_1__c='Test Product',
            Product_External_ID__c = '12345'
        );
        insert testProduct;
    }

    @isTest
    static void testGetInventoryDetails_Success() {
        // Create a test payload
        String jsonPayload = '{"model": "product.product", "name": "Test Product", "avg_cost": 10.5, "display_name": "Test Product Display", "free_qty": 5, "id": 12345, "qty_available": 20, "uom_id": 1, "categ_id": "Category1"}';
        
        RestRequest req = new RestRequest();
        req.requestURI = '/odoo/inventory/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonPayload);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Test.startTest();
        Odoo_Inventory_items.getInventoryDetails();
        Test.stopTest();
        
        System.assertEquals(200, res.statusCode);
        System.assert(res.responseBody.toString().contains('Success'));
    }

    @isTest
    static void testGetInventoryDetails_MissingId() {
        String jsonPayload = '{"model": "product.product", "name": "Test Product", "avg_cost": 10.5, "display_name": "Test Product Display", "free_qty": 5, "qty_available": 20, "uom_id": 1, "categ_id": "Category1"}';
        
        RestRequest req = new RestRequest();
        req.requestURI = '/odoo/inventory/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonPayload);
        RestContext.request = req;
        
        RestResponse res = new RestResponse();
        RestContext.response = res;
        
        Test.startTest();
        Odoo_Inventory_items.getInventoryDetails();
        Test.stopTest();
        
        System.assertEquals(400, res.statusCode);
        System.assert(res.responseBody.toString().contains('Missing required field: id'));
    }

   @isTest
static void testGetInventoryDetails_ProductNotFound() {
    String jsonPayload = '{"model": "product.product", "name": "Test Product", "avg_cost": 10.5, "display_name": "Test Product Display", "free_qty": 5, "id": 99999, "qty_available": 20, "uom_id": 1, "categ_id": "Category1"}';
    
    RestRequest req = new RestRequest();
    req.requestURI = '/odoo/inventory/';
    req.httpMethod = 'POST';
    req.requestBody = Blob.valueOf(jsonPayload);
    RestContext.request = req;
    
    RestResponse res = new RestResponse();
    RestContext.response = res;
    
    Test.startTest();
    Odoo_Inventory_items.getInventoryDetails();
    Test.stopTest();
    
    System.debug('Response Body: ' + res.responseBody.toString());
    System.assertEquals(404, res.statusCode, 'Expected a 404 status for a missing product.');
    
}


    @isTest
    static void testGetInventoryDetails_DMLFailure() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseServerError());
        Test.stopTest();
    }

    private class MockHttpResponseServerError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setStatusCode(500);
            res.setBody('{"status": "Error", "message": "DML Error"}');
            return res;
        }
    }
    
 
    @isTest
    static void testExceptionHandling() {
        // Set up test request and response
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        RestContext.request = request;
        RestContext.response = response;

        Test.startTest(); // Start test execution block

        // Case 1: Trigger CustomException by passing a payload without an 'id'
        request.requestBody = Blob.valueOf('{"model":"test","name":"test"}'); // Missing 'id'
        Odoo_Inventory_items.getInventoryDetails();
        System.assertEquals(400, response.statusCode, 'CustomException should return 400');

        // Case 2: Trigger QueryException by searching for a non-existent product
        request.requestBody = Blob.valueOf('{"id":9999999}'); // Assuming this ID doesn't exist
        Odoo_Inventory_items.getInventoryDetails();
        System.assertEquals(404, response.statusCode, 'QueryException should return 404');

        // Case 3: Trigger DmlException by inserting invalid Inventory__c record
        request.requestBody = Blob.valueOf('{"id":1, "avg_cost":null, "free_qty":null, "qty_available":null, "display_name":"Test"}');
        Odoo_Inventory_items.getInventoryDetails();
       

        // Case 4: Trigger a General Exception (Null Pointer)
        request.requestBody = null; // This will cause a NullPointerException
        Odoo_Inventory_items.getInventoryDetails();
        System.assertEquals(500, response.statusCode, 'General Exception should return 500');

        Test.stopTest(); // Stop test execution block
    }


   
}