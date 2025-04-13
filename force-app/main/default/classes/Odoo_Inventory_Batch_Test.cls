@isTest
public class Odoo_Inventory_Batch_Test {

    // Test method 1: Test batch success scenario
    @isTest
    static void testBatchSuccess() {
        
        // Set up products
        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < 5; i++) {
            products.add(new Product2(
                Name = 'Test Product ' + i,
                Variant_ExternalId__c = String.valueOf(i)
            ));
        }
        insert products;

        // Set up the mock response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Initialize Odoo credentials
        Odoo_Inventory_Batch.baseUrl = 'https://test.odoo.com';
        Odoo_Inventory_Batch.uid = 1;
        Odoo_Inventory_Batch.ODOO_DB = 'test_db';
        Odoo_Inventory_Batch.ODOO_PASSWORD = 'test_password';

        // Start the test, execute the batch once
        Test.startTest();
        Odoo_Inventory_Batch batch = new Odoo_Inventory_Batch();
        Database.executeBatch(batch);
        Test.stopTest();

        // Validate the inventory records created
        List<Inventory__c> inventories = [SELECT Id, Product__c, Available_Quantity__c, Free_Quantity__c FROM Inventory__c];
        System.assertEquals(5, inventories.size(), 'The number of inventory records should match the number of products.');
        
        for (Inventory__c inv : inventories) {
            System.assertNotEquals(null, inv.Available_Quantity__c, 'Available quantity should be populated.');
            System.assertNotEquals(null, inv.Free_Quantity__c, 'Free quantity should be populated.');
        }
    }

    // Test method 2: Test batch with HTTP error scenario
  @isTest
static void testBatchWithHttpError() {
    
    // Set up products
    List<Product2> products = new List<Product2>();
    for (Integer i = 0; i < 2; i++) {
        products.add(new Product2(
            Name = 'Test Product ' + i,
            Variant_ExternalId__c = String.valueOf(i)
        ));
    }
    insert products;

    // Set up the mock response (successful authentication and error response)
    Test.setMock(HttpCalloutMock.class, new MockHttpErrorResponseGenerator());

    // Initialize Odoo credentials
    Odoo_Inventory_Batch.baseUrl = 'https://test.odoo.com';
    Odoo_Inventory_Batch.uid = 1;
    Odoo_Inventory_Batch.ODOO_DB = 'test_db';
    Odoo_Inventory_Batch.ODOO_PASSWORD = 'test_password';

    // Start the test, execute the batch once
    Test.startTest();
    Odoo_Inventory_Batch batch = new Odoo_Inventory_Batch();
    Database.executeBatch(batch);
    Test.stopTest();

    // Validate that no inventory records were created due to the error
    List<Inventory__c> inventories = [SELECT Id FROM Inventory__c];
    System.assertEquals(0, inventories.size(), 'No inventory records should be created when the HTTP callout fails.');
}


    // Test method 3: Test batch with exception in parsing scenario
    @isTest
    static void testBatchWithExceptionInParsing() {
        
        // Set up products
        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < 2; i++) {
            products.add(new Product2(
                Name = 'Test Product ' + i,
                Variant_ExternalId__c = String.valueOf(i)
            ));
        }
        insert products;

        // Set up the mock response for parsing error
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseForParsingError());

        // Initialize Odoo credentials
        Odoo_Inventory_Batch.baseUrl = 'https://test.odoo.com';
        Odoo_Inventory_Batch.uid = 1;
        Odoo_Inventory_Batch.ODOO_DB = 'test_db';
        Odoo_Inventory_Batch.ODOO_PASSWORD = 'test_password';

        // Start the test, execute the batch once
        Test.startTest();
        Odoo_Inventory_Batch batch = new Odoo_Inventory_Batch();
        Database.executeBatch(batch);
        Test.stopTest();

        // Validate that no inventory records were created due to parsing error
        List<Inventory__c> inventories = [SELECT Id FROM Inventory__c];
        System.assertEquals(0, inventories.size(), 'No inventory records should be created when there is an error in parsing.');
    }

    // Mock class to simulate a successful HTTP response
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String responseBody = '{"jsonrpc": "2.0", "result": [{"id": 0, "qty_available": 100, "free_qty": 50}, {"id": 1, "qty_available": 200, "free_qty": 100},{"id": 2, "qty_available": 200, "free_qty": 100},{"id": 3, "qty_available": 200, "free_qty": 100},{"id": 4, "qty_available": 200, "free_qty": 100}]}';
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(responseBody);
            res.setHeader('Set-Cookie', 'session_id=mockSessionId; Path=/; HttpOnly');
            return res;
        }
    }

    // Mock class to simulate an HTTP error response
  class MockHttpErrorResponseGenerator implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();

        // Mock a successful authentication response
        // Simulating a response where authentication is successful
        if (req.getEndpoint().contains('authenticate')) {
            res.setStatusCode(200);
            res.setBody('{"session_id": "mockSessionId"}'); // Simulating session authentication
        } else {
            // Simulate an error response (e.g., HTTP 500 for the actual API call)
            res.setStatusCode(500);  // Simulate an HTTP 500 server error
            res.setBody('{"error": "Authentication failed"}');  // Simulate an authentication failure in response body
        }
        
        res.setHeader('Set-Cookie', 'session_id=mockSessionId; Path=/; HttpOnly');
        return res;
    }
}

    // Mock class to simulate a parsing error in the HTTP response
    class MockHttpResponseForParsingError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String responseBody = '{"jsonrpc": "2.0", "result": [{id: 1, qty_available: "100", free_qty: 50}]}'; // missing quotes around keys
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(responseBody);
            res.setHeader('Set-Cookie', 'session_id=mockSessionId; Path=/; HttpOnly');
            return res;
        }
    }
}