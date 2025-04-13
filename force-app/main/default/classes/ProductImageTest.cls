@isTest
private class ProductImageTest {

    @isTest
    static void testProductImageWithValidRecordId() {
        // Create test data for Product2
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            Image_URL__c = 'http://example.com/image.jpg',
            Product_Category__c = 'Boys',
            Product_Type__c = 'POLO',
            cgcloud__State__c = 'Active',
            IsActive = true,
            URL__c = 'http://example.com/product'
        );
        insert testProduct;

        // Call the method with the valid record Id
        Test.startTest();
        List<Product2> result = ProductImage.product(testProduct.Id);
        Test.stopTest();

        // Assertions to check the results
        System.assertNotEquals(0, result.size(), 'Product should be found');
        System.assertEquals(testProduct.Id, result[0].Id, 'Product ID should match');
        System.assertEquals(testProduct.Name, result[0].Name, 'Product Name should match');
        System.assertEquals(testProduct.Image_URL__c, result[0].Image_URL__c, 'Image URL should match');
        System.assertEquals(testProduct.Product_Category__c, result[0].Product_Category__c, 'Product Category should match');
        System.assertEquals(testProduct.Product_Type__c, result[0].Product_Type__c, 'Product Type should match');
        System.assertEquals(testProduct.cgcloud__State__c, result[0].cgcloud__State__c, 'State should match');
        System.assertEquals(testProduct.IsActive, result[0].IsActive, 'Product should be active');
        System.assertEquals(testProduct.URL__c, result[0].URL__c, 'URL should match');
    }   
}