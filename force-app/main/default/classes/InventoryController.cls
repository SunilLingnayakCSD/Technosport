public with sharing class InventoryController {

    @AuraEnabled(cacheable=true)
    public static List<Inventory__c> getInventoryRecords() {
        
        // Query the custom Inventory object with required fields
         return [SELECT Id, Product_Name__c,Free_Quantity__c,Inventory_Stock_Status__c,Stock_Status__c
                 FROM Inventory__c 
                 WHERE Product__c != ''];
    }

@AuraEnabled(cacheable=true)
public static List<Inventory__c> getSearchRecords(String searchTerm, String productCategory, String productCategory1, String stockStatus) {
    // Build the dynamic query with search functionality
    String query = 'SELECT Id, Product_Name__c, Available_Quantity__c, Avg_Cost__c, Free_Quantity__c, ' + 
                   'Inventory_Stock_Status__c, Product_Category1__c, Product_Category__c,Stock_Status__c ' + 
                   'FROM Inventory__c WHERE ';
    
    List<String> conditions = new List<String>();
    
    // Add search term condition
    if (String.isNotBlank(searchTerm)) {
        conditions.add('(Product_Name__c LIKE \'%' + String.escapeSingleQuotes(searchTerm) + '%\')');
    }
    
    // Add product category filter
    if (String.isNotBlank(productCategory)) {
        conditions.add('Product_Category__c = \'' + String.escapeSingleQuotes(productCategory) + '\'');
    }
    
    // Add product category1 filter
    if (String.isNotBlank(productCategory1)) {
        conditions.add('Product_Category1__c = \'' + String.escapeSingleQuotes(productCategory1) + '\'');
    }
    
    // Add stock status filter
    if (String.isNotBlank(stockStatus)) {
        conditions.add('Inventory_Stock_Status__c LIKE \'%' + String.escapeSingleQuotes(stockStatus) + '%\'');
    }
    
    // If no filters are applied, return all records
    if (conditions.isEmpty()) {
        query = query.removeEnd('WHERE ');
    } else {
        query += String.join(conditions, ' AND ');
    }
    
    return Database.query(query);
}

@AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getPicklistValues(String objectName, String fieldName) {
        List<Map<String, String>> picklistValues = new List<Map<String, String>>();
        
        // Get describe information for the object
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        
        if (objType != null) {
            // Get the field describe result
            Schema.DescribeFieldResult fieldResult = objType.getDescribe()
                .fields.getMap()
                .get(fieldName)
                .getDescribe();
            
            // Get picklist values
            if (fieldResult.getType() == Schema.DisplayType.PICKLIST) {
                for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
                    if (entry.isActive()) { // Only include active values
                        picklistValues.add(new Map<String, String>{
                            'label' => entry.getLabel(),
                            'value' => entry.getValue()
                        });
                    }
                }
            }
        }
        
        return picklistValues;
    }
}