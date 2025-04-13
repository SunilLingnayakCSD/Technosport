@isTest
public class ProductCarouselControllerTest {
    
    // Test method for getRecentProducts
    @isTest
    static void testGetRecentProducts() {
        // Create test products
        Product2 product1 = new Product2(Name = 'Product 1', Image_url__c = 'https://example.com/image1.jpg');
        Product2 product2 = new Product2(Name = 'Product 2', Image_url__c = 'https://example.com/image2.jpg');
        Product2 product3 = new Product2(Name = 'Product 3', Image_url__c = 'https://example.com/image3.jpg');
        
        // Insert products in reverse order so that Product 3 is the most recent
        insert new List<Product2>{product3, product2, product1};
        
        // Test getRecentProducts method
        Test.startTest();
        List<Product2> products = ProductCarouselController.getRecentProducts();
        Test.stopTest();
        
        // Assert that products are returned and not empty
        System.assertNotEquals(products, null, 'The product list should not be null.');
        System.assertEquals(products.size(), 3, 'The product list should contain 3 products.');
        
        // Additional assertions to check if product details are correctly returned
        System.assertEquals(products[0].Name, 'Product 3', 'The most recent product should be Product 3.');
        System.assertEquals(products[1].Name, 'Product 2', 'The second most recent product should be Product 2.');
        System.assertEquals(products[2].Name, 'Product 1', 'The third most recent product should be Product 1.');
        
        // Check Image_url__c is properly populated
        System.assertEquals(products[0].Image_url__c, 'https://example.com/image3.jpg', 'The image URL of the most recent product should match.');
    }
}