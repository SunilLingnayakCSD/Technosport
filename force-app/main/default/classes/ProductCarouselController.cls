public class ProductCarouselController {
	@AuraEnabled(cacheable=true)
    public static List<Product2> getRecentProducts() {
        // Query for recent products (adjust the fields as per your Salesforce schema)
        List<Product2> products = [SELECT Id, Name, Image_url__c FROM Product2 ORDER BY CreatedDate DESC LIMIT 10];
        return products;
    }
}