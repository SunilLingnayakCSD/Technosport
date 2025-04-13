@isTest
public class CreateQuoteControllerTest {

    @isTest
    static void testCreateQuote() {
        // Create a test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create a test Pricebook2
       Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        // Create a test Order
        Order testOrder = new Order(
            Name = 'Test Order',
            AccountId = testAccount.Id,
            Pricebook2Id = standardPricebook.Id,
            Status = 'Draft',
            EffectiveDate = System.today(),
            Bundle_Quantity__c = 2  // Setting a value greater than 0 for testing the bundle logic
        );
        insert testOrder;

        // Create test OrderItem associated with the Order
        Product2 testProduct = new Product2(Name = 'Test Product', isActive = true);
        insert testProduct;
        
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert testPricebookEntry;

        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            PricebookEntryId = testPricebookEntry.Id,
            Quantity = 2,
            UnitPrice = 100,
            Product2Id = testProduct.Id,
            Product_Type__c = 'Catalogue', // Using 'Catalogue' type to test the conditional logic
            S__c = '1',
            M__c = '1',
            L__c = '1',
            XL__c = '1',
            XXL__c = '1',
            XXXL__c = '1',
            Description = 'Test Order Item'
        );
        insert testOrderItem;

        // Prepare order data to pass to the createQuote method
        List<Order> orderData = new List<Order>{ testOrder };

        // Run the test
        Test.startTest();
         Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());
        CreateQuoteController.createQuote(orderData);
        Test.stopTest();

        // Verify that Quotes are created
        List<Quote> createdQuotes = [SELECT Id, Name, OrderId__c FROM Quote WHERE OrderId__c = :testOrder.Id];
        System.assertEquals(2, createdQuotes.size());  // One quote for each bundle

        // Verify that QuoteLineItems are created
        List<QuoteLineItem> createdQuoteLineItems = [SELECT Id, Quantity, Product2Id FROM QuoteLineItem WHERE QuoteId IN :createdQuotes];
        System.assertEquals(2, createdQuoteLineItems.size()); // Expecting 2 QuoteLineItems because we have 1 OrderItem and 2 bundles

        // Optionally, verify data correctness
        System.assertEquals('Test Order', createdQuotes[0].Name);
        System.assertEquals(testProduct.Id, createdQuoteLineItems[0].Product2Id);
        System.assertEquals(2, createdQuoteLineItems[0].Quantity);
    }
     @isTest
    static void testCreateQuoteBlank() {
        // Create a test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create a test Pricebook2
       Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        // Create a test Order
        Order testOrder = new Order(
            Name = 'Test Order',
            AccountId = testAccount.Id,
            Pricebook2Id = standardPricebook.Id,
            Status = 'Draft',
            EffectiveDate = System.today(),
            Bundle_Quantity__c = 0  // Setting a value greater than 0 for testing the bundle logic
        );
        insert testOrder;

        // Create test OrderItem associated with the Order
        Product2 testProduct = new Product2(Name = 'Test Product', isActive = true);
        insert testProduct;
        
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert testPricebookEntry;

        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            PricebookEntryId = testPricebookEntry.Id,
            Quantity = 2,
            UnitPrice = 100,
            Product2Id = testProduct.Id,
            Product_Type__c = 'Blank', // Using 'Catalogue' type to test the conditional logic
            S__c = '1',
            M__c = '1',
            L__c = '1',
            XL__c = '1',
            XXL__c = '1',
            XXXL__c = '1',
            Description = 'Test Order Item'
        );
        insert testOrderItem;

        // Prepare order data to pass to the createQuote method
        List<Order> orderData = new List<Order>{ testOrder };

        // Run the test
        Test.startTest();
         Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());
        CreateQuoteController.createQuote(orderData);
        Test.stopTest();

        // Verify that Quotes are created
        List<Quote> createdQuotes = [SELECT Id, Name, OrderId__c FROM Quote WHERE OrderId__c = :testOrder.Id];
        System.assertEquals(1, createdQuotes.size());  // One quote for each bundle

        // Verify that QuoteLineItems are created
        List<QuoteLineItem> createdQuoteLineItems = [SELECT Id, Quantity, Product2Id FROM QuoteLineItem WHERE QuoteId IN :createdQuotes];
        System.assertEquals(1, createdQuoteLineItems.size()); // Expecting 2 QuoteLineItems because we have 1 OrderItem and 2 bundles

        // Optionally, verify data correctness
        System.assertEquals('Test Order', createdQuotes[0].Name);
        System.assertEquals(testProduct.Id, createdQuoteLineItems[0].Product2Id);
        System.assertEquals(2, createdQuoteLineItems[0].Quantity);
    }
}