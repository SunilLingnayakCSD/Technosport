@isTest
public class CreateQuoteControllerTest {
    
    // Mock HTTP response generator for any callouts
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
             if (req.getEndpoint().contains('auth')) {
            res.setBody('{"jsonrpc": "2.0", "id": 1, "result": "fake_session_cookie"}');
            res.setHeader('Set-Cookie', 'fake_session_cookie=123456; Path=/; HttpOnly');
             }else{
                 res.setBody('{"success":true}');
             }
            
            
            res.setStatusCode(200);
            return res;
        }
    }

    @TestSetup
    static void setupTestData() {
        // Set mock callout class for the entire test setup if needed
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Create test accounts with required address fields
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingPostalCode = '12345',
            BillingCity = 'Test City',
            BillingStreet = '123 Test Street'
        );
        insert testAccount;

        // Create test products
        Product2 blankProduct = new Product2(
            Name = 'Blank Product',
            Product_Type1__c = 'Product Template',
            IsActive = true
        );
        Product2 catalogProduct = new Product2(
            Name = 'Catalog Product',
            Product_Type1__c = 'Product Variant',
            IsActive = true
        );
        insert new List<Product2>{blankProduct, catalogProduct};

        // Get standard pricebook
        Id standardPricebookId = Test.getStandardPricebookId();

        // Create pricebook entries
        PricebookEntry blankPbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = blankProduct.Id,
            UnitPrice = 100,
            IsActive = true,
            UseStandardPrice = false
        );
        PricebookEntry catalogPbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = catalogProduct.Id,
            UnitPrice = 200,
            IsActive = true,
            UseStandardPrice = false
        );
        insert new List<PricebookEntry>{blankPbe, catalogPbe};

        // Create test orders
        Order regularOrder = new Order(
            Name = 'Regular Order',
            AccountId = testAccount.Id,
            EffectiveDate = System.today(),
            Status = 'Draft',
            Pricebook2Id = standardPricebookId,
            Bundle_Quantity__c = 2,
            isFutureProduct__c = false,
            isFutureQuoShouuldCreate__c = false
        );
        
        Order futureOrder = new Order(
            Name = 'Future Order',
            AccountId = testAccount.Id,
            EffectiveDate = System.today().addDays(30),
            Status = 'Draft',
            Pricebook2Id = standardPricebookId,
            Bundle_Quantity__c = 3,
            isFutureProduct__c = true,
            isFutureQuoShouuldCreate__c = true
        );
        
        Order noBundleOrder = new Order(
            Name = 'No Bundle Order',
            AccountId = testAccount.Id,
            EffectiveDate = System.today(),
            Status = 'Draft',
            Pricebook2Id = standardPricebookId,
            Bundle_Quantity__c = 0,
            isFutureProduct__c = false,
            isFutureQuoShouuldCreate__c = false
        );
        
        insert new List<Order>{regularOrder, futureOrder, noBundleOrder};

        // Create order items
        OrderItem blankOrderItem = new OrderItem(
            OrderId = regularOrder.Id,
            PricebookEntryId = blankPbe.Id,
            Quantity = 5,
            UnitPrice = 100,
            Product2Id = blankProduct.Id,
            Product_Type__c = 'Blank'
        );
        
        OrderItem catalogOrderItem = new OrderItem(
            OrderId = regularOrder.Id,
            PricebookEntryId = catalogPbe.Id,
            Quantity = 10,
            UnitPrice = 200,
            Product2Id = catalogProduct.Id,
            Product_Type__c = 'Catalogue',
            isUpcomingVarient__c = false
        );
        
        OrderItem futureCatalogItem = new OrderItem(
            OrderId = futureOrder.Id,
            PricebookEntryId = catalogPbe.Id,
            Quantity = 15,
            UnitPrice = 200,
            Product2Id = catalogProduct.Id,
            Product_Type__c = 'Catalogue',
            isUpcomingVarient__c = true
        );
        
        OrderItem noBundleOrderItem = new OrderItem(
            OrderId = noBundleOrder.Id,
            PricebookEntryId = catalogPbe.Id,
            Quantity = 20,
            UnitPrice = 200,
            Product2Id = catalogProduct.Id,
            Product_Type__c = 'Catalogue',
            isUpcomingVarient__c = false
        );
        
        insert new List<OrderItem>{blankOrderItem, catalogOrderItem, futureCatalogItem, noBundleOrderItem};
    }

    @isTest
    static void testCreateQuoteWithRegularOrder() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        List<Order> testOrders = [SELECT Id,Name,Pricebook2Id,EffectiveDate,Description, AccountId,Bundle_Quantity__c, 
                                isFutureProduct__c, isFutureQuoShouuldCreate__c FROM Order WHERE Name = 'Regular Order'];
        System.assertEquals(1, testOrders.size(), 'Test order not found');
        
        Test.startTest();
        CreateQuoteController.createQuote(testOrders);
        Test.stopTest();
        
        // Verify quotes were created
        List<Quote> quotes = [SELECT Id, Name, isNextAvailbleProductQuote__c FROM Quote WHERE OrderId__c = :testOrders[0].Id];
        System.assertEquals(2, quotes.size(), 'Should create 2 quotes for bundle quantity of 2');
        System.assertEquals(false, quotes[0].isNextAvailbleProductQuote__c, 'Should not be future product quote');
        
        // Verify quote line items
       // List<QuoteLineItem> qlis = [SELECT Id, Product_Type__c FROM QuoteLineItem WHERE QuoteId IN :quotes];
       // System.assertEquals(4, qlis.size(), 'Should create 2 line items for each quote (1 blank + 1 catalog)');
    }

    @isTest
    static void testCreateQuoteWithFutureOrder() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        List<Order> testOrders = [SELECT Id,Name,Pricebook2Id,EffectiveDate,Description, AccountId, Bundle_Quantity__c, 
                                isFutureProduct__c, isFutureQuoShouuldCreate__c FROM Order WHERE Name = 'Future Order'];
        System.assertEquals(1, testOrders.size(), 'Test order not found');
        
        Test.startTest();
        CreateQuoteController.createQuote(testOrders);
        Test.stopTest();
        
        // Verify quotes were created
        List<Quote> quotes = [SELECT Id, Name, isNextAvailbleProductQuote__c FROM Quote WHERE OrderId__c = :testOrders[0].Id];
        System.assertEquals(1, quotes.size(), 'Should create 1  future quote');
        
        // Verify future quote
        List<Quote> futureQuotes = [SELECT Id FROM Quote WHERE isNextAvailbleProductQuote__c = true AND OrderId__c = :testOrders[0].Id];
        System.assertEquals(1, futureQuotes.size(), 'Should create 1 future quote');
        
        // Verify future quote line items
      //  List<QuoteLineItem> futureQlis = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :futureQuotes[0].Id];
       // System.assertEquals(1, futureQlis.size(), 'Future quote should have 1 line item');
    }

    @isTest
    static void testCreateQuoteWithNoBundleOrder() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        List<Order> testOrders = [SELECT Id, Name, Pricebook2Id,AccountId,Description, EffectiveDate, Bundle_Quantity__c, 
                                isFutureProduct__c, isFutureQuoShouuldCreate__c FROM Order WHERE Name = 'No Bundle Order'];
        System.assertEquals(1, testOrders.size(), 'Test order not found');
        
        Test.startTest();
        CreateQuoteController.createQuote(testOrders);
        Test.stopTest();
        
        // Verify no quotes were created (since bundle quantity is 0)
        List<Quote> quotes = [SELECT Id FROM Quote WHERE OrderId__c = :testOrders[0].Id];
        System.assertEquals(0, quotes.size(), 'Should not create quotes when bundle quantity is 0');
    }

    @isTest
    static void testCreateQuoteWithEmptyOrderList() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        CreateQuoteController.createQuote(new List<Order>());
        Test.stopTest();
        
        // Verify no quotes were created
        List<Quote> quotes = [SELECT Id FROM Quote];
        System.assertEquals(0, quotes.size(), 'No quotes should be created for empty order list');
    }

    @isTest
    static void testCreateQuoteWithMultipleOrders() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        List<Order> testOrders = [SELECT Id,Name,Pricebook2Id,Description, AccountId, EffectiveDate, Bundle_Quantity__c, 
                                isFutureProduct__c, isFutureQuoShouuldCreate__c FROM Order 
                                WHERE Name IN ('Regular Order', 'Future Order')];
        System.assertEquals(2, testOrders.size(), 'Test orders not found');
        
        Test.startTest();
        CreateQuoteController.createQuote(testOrders);
        Test.stopTest();
        
        // Verify quotes were created for both orders
        List<Quote> quotes = [SELECT Id, OrderId__c FROM Quote];
        System.assertEquals(6, quotes.size(), 'Should create 2 quotes for regular order + 4 for future order');
    }

    @isTest
    static void testErrorHandling() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        List<Order> testOrders = [SELECT Id, Name, Pricebook2Id,AccountId,Description, EffectiveDate, Bundle_Quantity__c, 
                                isFutureProduct__c, isFutureQuoShouuldCreate__c FROM Order WHERE Name = 'Regular Order'];
        System.assertEquals(1, testOrders.size(), 'Test order not found');
        
        // Force a DML exception by making the Order Name too long
        testOrders[0].Name = 'This is a very long order name that exceeds the 80 character limit and should cause an exception when saved';
        
        // Verify the exception is thrown
        Boolean exceptionThrown = false;
        try {
            update testOrders[0];
        } catch (DmlException e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Expected DML exception not thrown');
        
        Test.startTest();
        // This should handle the error gracefully
        CreateQuoteController.createQuote(testOrders);
        Test.stopTest();
        
        // Verify the error was handled (no quotes created for invalid order)
        List<Quote> quotes = [SELECT Id FROM Quote WHERE OrderId__c = :testOrders[0].Id];
      //  System.assertEquals(0, quotes.size(), 'No quotes should be created for invalid order');
    }
}