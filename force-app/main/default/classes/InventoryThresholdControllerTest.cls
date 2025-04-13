@isTest
public class InventoryThresholdControllerTest {

    // Test method for getPicklistValues()
    @isTest
    public static void testGetPicklistValues() {
        // Dynamically fetch picklist values for both fields
        Test.startTest();

        Map<String, List<Map<String, String>>> result = InventoryThresholdController.getPicklistValues();
        
        // Assert that the result contains the keys for dynamic picklists
        System.assert(result.containsKey('Product_Category__c'), 'Product_Category__c key should exist');
        System.assert(result.containsKey('Product_Category1__c'), 'Product_Category1__c key should exist');
        
        // Dynamically check for non-empty lists
        System.assertNotEquals(result.get('Product_Category__c').size(), 0, 'Product_Category__c should have picklist values');
        System.assertNotEquals(result.get('Product_Category1__c').size(), 0, 'Product_Category1__c should have picklist values');

        Test.stopTest();
    }

    // Test method for getInventoryRecords()
    @isTest
    public static void testGetInventoryRecords() {
        // Create dynamic data for inventory records
        String productCategory = 'BOYS';  // Make sure this is a valid picklist value
        String productCategory1 = 'TRACK PANT';  // Make sure this is a valid picklist value

        // Insert inventory record with valid picklist values
        Inventory__c inv = new Inventory__c(
            Product_Category__c = productCategory,
            Product_Category1__c = productCategory1,
            High_Quantity_Threshold_Min__c = 10,
            High_Quantity_Threshold_Max__c = 20,
            Medium_Quantity_Threshold_Min__c = 5,
            Medium_Quantity_Threshold_Max__c = 15,
            Low_Quantity_Threshold_Min__c = 1,
            Low_Quantity_Threshold_Max__c = 5
        );
        insert inv;

        Test.startTest();
        List<Inventory__c> result = InventoryThresholdController.getInventoryRecords(productCategory, productCategory1);
        Test.stopTest();

        // Assert that the inventory records returned match the input parameters
        System.assert(result.size() > 0, 'The inventory records should be returned');
        
        // Assert that the fields are accessible (this is why we need to query for these fields)
      //  System.assertEquals(result[0].Product_Category__c, productCategory, 'Product_Category__c should match');
       // System.assertEquals(result[0].Product_Category1__c, productCategory1, 'Product_Category1__c should match');
    }

    // Test method for saveInventoryThresholds()
    @isTest
    public static void testSaveInventoryThresholds() {
        // Create dynamic data for inventory record
        String productCategory = 'BOYS';  // Make sure this is a valid picklist value
        String productCategory1 = 'JACKET';  // Make sure this is a valid picklist value

        Inventory__c inv = new Inventory__c(
            Product_Category__c = productCategory,
            Product_Category1__c = productCategory1
        );
        insert inv;

        // Define dynamic threshold values
        Integer highQuantityThresholdMin = 10;
        Integer highQuantityThresholdMax = 20;
        Integer mediumQuantityThresholdMin = 5;
        Integer mediumQuantityThresholdMax = 15;
        Integer lowQuantityThresholdMin = 1;
        Integer lowQuantityThresholdMax = 5;

        // Call the method to save inventory threshold values dynamically
        Test.startTest();
        InventoryThresholdController.saveInventoryThresholds(
            productCategory, productCategory1,
            highQuantityThresholdMin, highQuantityThresholdMax,
            mediumQuantityThresholdMin, mediumQuantityThresholdMax,
            lowQuantityThresholdMin, lowQuantityThresholdMax
        );
        Test.stopTest();

        // Query the updated records with the required fields
        Inventory__c updatedInv = [SELECT High_Quantity_Threshold_Min__c, High_Quantity_Threshold_Max__c,
                                           Medium_Quantity_Threshold_Min__c, Medium_Quantity_Threshold_Max__c,
                                           Low_Quantity_Threshold_Min__c, Low_Quantity_Threshold_Max__c,
                                           Product_Category__c, Product_Category1__c
                                   FROM Inventory__c WHERE Id = :inv.Id LIMIT 1];

        // Assert that the thresholds have been updated dynamically
        System.assertEquals(updatedInv.High_Quantity_Threshold_Min__c, highQuantityThresholdMin, 'High threshold min should be dynamic');
        System.assertEquals(updatedInv.High_Quantity_Threshold_Max__c, highQuantityThresholdMax, 'High threshold max should be dynamic');
        System.assertEquals(updatedInv.Medium_Quantity_Threshold_Min__c, mediumQuantityThresholdMin, 'Medium threshold min should be dynamic');
        System.assertEquals(updatedInv.Medium_Quantity_Threshold_Max__c, mediumQuantityThresholdMax, 'Medium threshold max should be dynamic');
        System.assertEquals(updatedInv.Low_Quantity_Threshold_Min__c, lowQuantityThresholdMin, 'Low threshold min should be dynamic');
        System.assertEquals(updatedInv.Low_Quantity_Threshold_Max__c, lowQuantityThresholdMax, 'Low threshold max should be dynamic');
    }
}