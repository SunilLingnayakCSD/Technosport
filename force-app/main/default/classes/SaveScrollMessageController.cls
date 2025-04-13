// public with sharing class SaveScrollMessageController {

//     @AuraEnabled
//     public static String scrollMessage(String message) {
//         try {
//             // Query for active products, consider adding a LIMIT if needed to avoid large queries
//             List<Product2> productsToUpdate = [SELECT Id, Scroll_Message__c FROM Product2 WHERE IsActive = true];
//              System.debug('productsToUpdate: ' + productsToUpdate);
//             // Ensure there are products to update
//             if (productsToUpdate.isEmpty()) {
//                 return 'No active products found to update.';
//             }
            
//             // Update the scroll message field for all products
//             for (Product2 prod : productsToUpdate) {
//                 prod.Scroll_Message__c = message;
//                 System.debug('Updated product: ' + prod.Id + ' with message: ' + prod.Scroll_Message__c);
//             }
            
//             // Perform the update in a bulk-safe way
//             update productsToUpdate;
            
//             return 'Message updated successfully for ' + productsToUpdate.size() + ' products.';
            
//         } catch (Exception e) {
//             // Log exception for further debugging and handling
//             System.debug('Error updating product messages: ' + e.getMessage());
//             throw new AuraHandledException('Error updating product messages: ' + e.getMessage());
//         }
//     }
// }



public with sharing class SaveScrollMessageController {

    // Method to retrieve the scroll message from the custom setting
    @AuraEnabled(cacheable=true)
    public static String getScrollMessage() {
        try {
            // Query to fetch the scroll message from the custom setting
            List<scrollMessages__c> settings = [SELECT Message__c FROM scrollMessages__c LIMIT 1];
            
            if (settings.isEmpty()) {
                return 'No scroll message found in custom setting.';
            }

            return settings[0].Message__c;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching scroll message: ' + e.getMessage());
        }
    }

    // Method to update the scroll message in the custom setting (only if the record exists)
    @AuraEnabled
    public static String updateScrollMessage(String message) {
        try {
            // Ensure the message is not empty
            if (String.isEmpty(message)) {
                return 'Message cannot be empty.';
            }

            // Query the custom setting record (List Custom Setting)
            List<scrollMessages__c> existingMessages = [SELECT Id, Message__c FROM scrollMessages__c WHERE Name = 'Message' LIMIT 1];
            
            // Check if the custom setting record exists
            if (existingMessages.isEmpty()) {
                return 'No scroll message record found in custom setting to update.';
            } else {
                // If the custom setting record exists, update it
                scrollMessages__c existingMessage = existingMessages[0];
                existingMessage.Message__c = message;
                update existingMessage; // Update the existing custom setting record
                return 'Message updated successfully .';
            }
        } catch (Exception e) {
            // Handle any exceptions and provide feedback
            throw new AuraHandledException('Error updating scroll message: ' + e.getMessage());
        }
    }
}