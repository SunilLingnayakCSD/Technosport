@isTest
public class NewlaunchesProductTest {

    @isTest
    static void testGetRecentProducts() {
        // Get the standard pricebook and activate it
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        // Create a recent product (within last 2 days)
        Product2 recentProduct = new Product2(
            Name = 'Recent Product',
            isActive = true,
            Image_url__c = 'http://example.com/recent.jpg',
            Video_Url__c = 'http://example.com/recent.mp4',
            cgcloud__Category__c = 'CATALOUGE PRODUCT',
            isFutureProduct__c = false,
            Product_Template__c = null,
            is_New_Launch_Product__c = true
        );
        insert recentProduct;

        // Pricebook entry for recent product
        PricebookEntry pbEntryRecent = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = recentProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbEntryRecent;

        // Variant for recent product
        Product2 variant1 = new Product2(
            Name = 'Variant 1',
            Product__c = recentProduct.Id,
            Color__c = 'Red',
            Size__c = 'M',
            Variant_ExternalId__c = 'V1',
            isActive = true
        );
        insert variant1;

        // Create an older product (simulate >2 days ago)
        Product2 olderProduct = new Product2(
            Name = 'Older Product',
            isActive = true,
            Image_url__c = 'http://example.com/old.jpg',
            Video_Url__c = 'http://example.com/old.mp4',
            cgcloud__Category__c = 'CATALOUGE PRODUCT',
            isFutureProduct__c = false,
            Product_Template__c = null,
            is_New_Launch_Product__c = true
        );
        insert olderProduct;

        Test.setCreatedDate(olderProduct.Id, System.now().addDays(-3));

        // Pricebook entry for older product
        PricebookEntry pbEntryOld = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = olderProduct.Id,
            UnitPrice = 200,
            IsActive = true
        );
        insert pbEntryOld;

        // Variant for older product
        Product2 variant2 = new Product2(
            Name = 'Variant 2',
            Product__c = olderProduct.Id,
            Color__c = 'Blue',
            Size__c = 'L',
            Variant_ExternalId__c = 'V2',
            isActive = true
        );
        insert variant2;

        Test.startTest();
        List<Map<String, Object>> products = NewlaunchesProduct.getRecentProducts(2, 0);
        Test.stopTest();

        // Validate results
        System.assertEquals(2, products.size(), 'Should return 2 products');
        System.assert(products[0].get('Name') == 'Recent Product' || products[1].get('Name') == 'Recent Product', 'Recent product should be included');
        System.assert(products[0].get('Name') == 'Older Product' || products[1].get('Name') == 'Older Product', 'Older product should also be included');
    }
}