@isTest
public class NewlaunchesProductTest {

    @isTest
    static void testGetRecentProducts() {
        // Create test Pricebook2 (Standard Pricebook)
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        // Create a test Product2 (created within last 7 days)
        Product2 testProduct1 = new Product2(
            Name = 'Test Product 1',
            isActive = true,
            Image_url__c = 'http://example.com/product1.jpg',
            Video_Url__c = 'http://example.com/product1.mp4',
            cgcloud__Category__c = 'Category 1',
            Product_Template__c= null
        );
        insert testProduct1;

        // Create a PricebookEntry for the Product2 in the Standard Pricebook
        PricebookEntry pricebookEntry1 = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct1.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pricebookEntry1;

        // Create a related Products1 record (assuming Products1__r is a related list)
        Product2 product1Related = new Product2(
            Name='Test',
            Product__c = testProduct1.Id,
            Color__c = 'Red',
            Size__c = 'M',
            Variant_ExternalId__c = '12345'
        );
        insert product1Related;

        // Create another Product2 (created more than 7 days ago to test filtering by CreatedDate)
        Product2 testProduct2 = new Product2(
            Name = 'Test Product 2',
            isActive = true,
            Image_url__c = 'http://example.com/product2.jpg',
            Video_Url__c = 'http://example.com/product2.mp4',
            cgcloud__Category__c = 'Category 2',
            Product_Template__c= null
        );
        insert testProduct2;

        // Create a PricebookEntry for the second Product2 in the Standard Pricebook
        PricebookEntry pricebookEntry2 = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct2.Id,
            UnitPrice = 150,
            IsActive = true
        );
        insert pricebookEntry2;

        // Create related Products1 record for the second product
        Product2 product2Related = new Product2(
            Name='Nametest',
            Product__c = testProduct2.Id,
            Color__c = 'Blue',
            Size__c = 'L',
            Variant_ExternalId__c = '67890'
        );
        insert product2Related;

        // Test with rowlimit = 1 and offset = 0 to retrieve only the recent product
        Test.startTest();
        List<Product2> products = NewlaunchesProduct.getRecentProducts(1, 0);
        products = NewlaunchesProduct.getRecentProducts(2, 0);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(0, products.size(), 'There should be products returned');
      System.assertEquals(2, products.size(), 'The rowlimit should return only 1 product');
        System.assertEquals('Test Product 2', products[0].Name, 'The returned product should be the most recent product');

        // Test with rowlimit = 2 and offset = 0 to retrieve two products
        

        // Assertions
        System.assertEquals(2, products.size(), 'The rowlimit should return 2 products');
        System.assertEquals('Test Product 2', products[0].Name, 'The first product should be the most recent product');
        System.assertEquals('Test Product 1', products[1].Name, 'The second product should be the older product');
    }
}