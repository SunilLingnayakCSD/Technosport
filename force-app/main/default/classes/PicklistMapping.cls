public class PicklistMapping {
    // Method to insert a new Mobile App Picklist Mapping record
    public static void createMobilePicklistMapping() {
        // Create a new record for Mobile App Picklist Mapping
        cgc_sync__Sync_Mobile_App_PL_Map_Ext__c newMapping = new cgc_sync__Sync_Mobile_App_PL_Map_Ext__c(
            cgc_sync__ParentPicklist__c = 'a0LC40000012Zz1MAE', // Replace with the actual Parent Picklist ID
            cgc_sync__Picklist_Value__c = 'CATALOUGE PRODUCT',                // Picklist Value
            //cgc_sync__Sort__c = '9',                            // Sort Order
            cgc_sync__ShortText_Language_1__c = 'CATALOUGE PRODUCT', // Short Text Translation (Language 1)
            cgc_sync__Text_Language_1__c = 'CATALOUGE PRODUCT',    // Text Translation (Language 1)
            cgc_sync__Business_Area__c= '0001'
        );

        try {
            // Insert the new record
            insert newMapping;
            // Debug the successful insertion
            System.debug('Record Inserted Successfully. ID: ' + newMapping.Id);
        } catch (DmlException e) {
            // Handle errors during the insert
            System.debug('Error Inserting Record: ' + e.getMessage());
        }
    }
}