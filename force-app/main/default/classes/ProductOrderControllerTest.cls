@IsTest
public class ProductOrderControllerTest {
    @TestSetup
    static void setup() {
        // Create common test data
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Product2 prod = new Product2(
            Name = 'Test Product',
            Image_url__c = 'http://example.com/image.jpg'
        );
        insert prod;

        Pricebook2 testPricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true
        );
        insert testPricebook;

        // Create Pricebook Entries
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true,
            UseStandardPrice = false
        );
        insert standardPbe;

        PricebookEntry testPbe = new PricebookEntry(
            Pricebook2Id = testPricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert testPbe;
    }

    @IsTest
    static void testGetFrequentlyOrderedProducts() {
        // Retrieve test data
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Pricebook2 testPricebook = [SELECT Id FROM Pricebook2 WHERE Name = 'Test Pricebook'];
        Product2 prod = [SELECT Id, Name, Image_url__c FROM Product2 LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :testPricebook.Id];

        // Create test Order
        Order testOrder = new Order(
            AccountId = acc.Id,
            EffectiveDate = System.today(),
            Status = 'Draft',
            Pricebook2Id = testPricebook.Id
        );
        insert testOrder;

        // Create Order Item
        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100.00
        );
        insert testOrderItem;

        // Update Order to Invoice status
        testOrder.Status = 'Invoice';
        update testOrder;

        Test.startTest();
        List<ProductOrderController.OrderProductWrapper> results = 
            ProductOrderController.getFrequentlyOrderedProducts();
        Test.stopTest();

        // Verify results
        System.assertEquals(1, results.size(), 'Should return one ordered product');
        System.assertEquals(prod.Name, results[0].productName, 'Product name mismatch');
        System.assertEquals(prod.Image_url__c, results[0].productImageUrl, 'Image URL mismatch');
        System.assertNotEquals(null, results[0].orderDate, 'Order date should be populated');
    }

    @IsTest
    static void testNoFrequentlyOrderedProducts() {
        // Create Order without Invoice status
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Pricebook2 testPricebook = [SELECT Id FROM Pricebook2 WHERE Name = 'Test Pricebook'];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :testPricebook.Id];

        Order testOrder = new Order(
            AccountId = acc.Id,
            EffectiveDate = System.today(),
            Status = 'Draft',
            Pricebook2Id = testPricebook.Id
        );
        insert testOrder;

        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100.00
        );
        insert testOrderItem;

        Test.startTest();
        List<ProductOrderController.OrderProductWrapper> results = 
            ProductOrderController.getFrequentlyOrderedProducts();
        Test.stopTest();

        // Verify no results
        System.assert(results.isEmpty(), 'Should return empty list for non-Invoice orders');
    }
}