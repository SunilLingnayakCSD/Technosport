public with sharing class InventoryThresholdController {

    // Return separate picklist values for Product_Category__c and Product_Category1__c
    @AuraEnabled(cacheable=true)
    public static Map<String, List<Map<String, String>>> getPicklistValues() {
        Map<String, List<Map<String, String>>> optionsMap = new Map<String, List<Map<String, String>>>();

        // Fetch picklist values for Product_Category__c
        Schema.DescribeFieldResult fieldResult = Inventory__c.Product_Category__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();
        
        List<Map<String, String>> productCategoryOptions = new List<Map<String, String>>();
        for (Schema.PicklistEntry entry : picklistEntries) {
            Map<String, String> option = new Map<String, String>();
            option.put('label', entry.getLabel());
            option.put('value', entry.getValue());
            productCategoryOptions.add(option);
        }
        optionsMap.put('Product_Category__c', productCategoryOptions);

        // Fetch picklist values for Product_Category1__c
        fieldResult = Inventory__c.Product_Category1__c.getDescribe();
        picklistEntries = fieldResult.getPicklistValues();
        
        List<Map<String, String>> productCategory1Options = new List<Map<String, String>>();
        for (Schema.PicklistEntry entry : picklistEntries) {
            Map<String, String> option = new Map<String, String>();
            option.put('label', entry.getLabel());
            option.put('value', entry.getValue());
            productCategory1Options.add(option);
        }
        optionsMap.put('Product_Category1__c', productCategory1Options);

        return optionsMap;
    }

    // Fetch inventory records based on both product categories
    @AuraEnabled
    public static List<Inventory__c> getInventoryRecords(String productCategory, String productCategory1) {
        return [SELECT High_Quantity_Threshold_Min__c, High_Quantity_Threshold_Max__c,
                        Medium_Quantity_Threshold_Min__c, Medium_Quantity_Threshold_Max__c,
                        Low_Quantity_Threshold_Min__c, Low_Quantity_Threshold_Max__c
                FROM Inventory__c
                WHERE Product_Category__c = :productCategory
                  AND Product_Category1__c = :productCategory1];
    }

    // Save inventory threshold values
    @AuraEnabled
    public static void saveInventoryThresholds(String productCategory, String productCategory1,
                                               Integer highQuantityThresholdMin, 
                                               Integer highQuantityThresholdMax,
                                               Integer mediumQuantityThresholdMin, 
                                               Integer mediumQuantityThresholdMax,
                                               Integer lowQuantityThresholdMin, 
                                               Integer lowQuantityThresholdMax) {
        List<Inventory__c> inventories = [SELECT Id, Product_Category__c, Product_Category1__c
                                          FROM Inventory__c 
                                          WHERE Product_Category__c = :productCategory
                                            AND Product_Category1__c = :productCategory1];

        for (Inventory__c inv : inventories) {
            inv.High_Quantity_Threshold_Min__c = highQuantityThresholdMin;
            inv.High_Quantity_Threshold_Max__c = highQuantityThresholdMax;
            inv.Medium_Quantity_Threshold_Min__c = mediumQuantityThresholdMin;
            inv.Medium_Quantity_Threshold_Max__c = mediumQuantityThresholdMax;
            inv.Low_Quantity_Threshold_Min__c = lowQuantityThresholdMin;
            inv.Low_Quantity_Threshold_Max__c = lowQuantityThresholdMax;
        }
        
        update inventories;
    }
}