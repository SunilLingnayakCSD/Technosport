@IsTest
private class InventoryControllerTest {
    
      @testSetup
    static void setupTestData() {
        // Create test Product2 records
        Product2 product1 = new Product2(Name = 'Product A');
        Product2 product2 = new Product2(Name = 'Product B');
        insert new List<Product2> { product1, product2 };

        // Create test Inventory__c records
        List<Inventory__c> inventories = new List<Inventory__c>{
            new Inventory__c(
                Available_Quantity__c = 100,
                Avg_Cost__c = 10,
                Free_Quantity__c = 50,
                Product__c = product1.Id
            ),
            new Inventory__c(
                Available_Quantity__c = 200,
                Avg_Cost__c = 20,
                Free_Quantity__c = 100,
                Product__c = product2.Id
            ),
            new Inventory__c(
                Available_Quantity__c = 50,
                Avg_Cost__c = 15,
                Free_Quantity__c = 25,
                Product__c = null // This record should not be returned by getInventoryRecords
            )
        };
        insert inventories;
    }

    @isTest
    static void testGetInventoryRecords() {
        // Call the method to be tested
        Test.startTest();
        List<Inventory__c> result = InventoryController.getInventoryRecords();
        Test.stopTest();

        // Verify the results
        System.assertEquals(2, result.size(), 'Expected 2 records with non-empty Product__c.');
        for (Inventory__c record : result) {
          //  System.assertNotEquals(null, record.Product__c, 'Product__c should not be null.');
        }
    }

// Test search with all filters
    @IsTest
    static void testSearchWithAllFilters() {
        Test.startTest();
        List<Inventory__c> results = InventoryController.getSearchRecords(
            'Premium', 'Mens', 'JACKET', 'High');
        Test.stopTest();
        
     }
    @IsTest
    static void testGetPicklistValuesValid() {
        Test.startTest();
        List<Map<String, String>> results = InventoryController.getPicklistValues(
            'Inventory__c', 'Product_Category__c');
        Test.stopTest();
       }
    
    @IsTest
    static void testGetPicklistValuesInvalidObject() {
        Test.startTest();
        List<Map<String, String>> results = InventoryController.getPicklistValues(
            'InvalidObject', 'Product_Category__c');
        Test.stopTest();
        
       
    }
    

    
    @IsTest
    static void testGetPicklistValuesNonPicklistField() {
        Test.startTest();
        List<Map<String, String>> results = InventoryController.getPicklistValues(
            'Inventory__c', 'Product_Name__c');
        Test.stopTest();
        
        
    }
    

    
    
}