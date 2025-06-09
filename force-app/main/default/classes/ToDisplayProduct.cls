// public with sharing class ToDisplayProduct {
//     @AuraEnabled(cacheable=true)
//     public static Product2 getProductDetails(Id recordId) {
//          return [SELECT Id, Name, Image_URL__c, Product_Category__c, Product_Type__c, cgcloud__State__c 
//                 FROM Product2 
//                 WHERE Id = :recordId AND (Product_Category__c!=null AND Product_Type__c!=null)
//                 LIMIT 1];
//     }
// }

// public class ToDisplayProduct {
//     @AuraEnabled(cacheable=true)
//     public static List<Product2> getProduct(Id recordId) { 
//         System.debug('Fetching Product for Record ID: ' + recordId);  
//         if (String.isBlank(recordId)) {
//             throw new AuraHandledException('Record ID cannot be blank');
//         }
//         return [SELECT Id, Name, Image_URL__c, Product_Category__c, Product_Type__c, cgcloud__State__c 
//                 FROM Product2 WHERE Id = :recordId LIMIT 1]; 
//     }
// }




public class ToDisplayProduct {
    @AuraEnabled(cacheable=true)
    public static Product2 getProductWithImage(Id recordId) { 
        System.debug('Fetching Product for Record ID: ' + recordId);  

        if (String.isBlank(recordId)) {
            throw new AuraHandledException('Record ID cannot be blank');
        }

        // Query for Product2 data
        Product2 product = [SELECT Id, Name, Image_URL__c,	Image__c, Product_Category__c, Product_Type__c, cgcloud__State__c, URL__c
                            FROM Product2 WHERE Id = :recordId LIMIT 1];

        // Query for the ContentDocumentLinks associated with the Product
        List<ContentDocumentLink> contentLinks = [
            SELECT ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :recordId
            LIMIT 1
        ];

        if (!contentLinks.isEmpty()) {
            // Query for the most recent ContentVersion related to the ContentDocumentId
            ContentVersion contentVersion = [
                SELECT Id, Title, ContentUrl, CreatedDate 
                FROM ContentVersion 
                WHERE ContentDocumentId = :contentLinks[0].ContentDocumentId 
                ORDER BY CreatedDate DESC 
                LIMIT 1
            ];

            // Assign the ContentUrl to the product's Image_URL__c
            product.Image_URL__c = contentVersion.ContentUrl;
        }

        return product; // Return the product with the image URL
    }
}







//Image_URL__c, Product_Category__c, Product_Type__c, cgcloud__State__c

// public with sharing class ToDisplayProduct {
//     @AuraEnabled(cacheable=true)
//     public static Product2 getProductDetails(Id productId) {
//         return [SELECT Id, Name, Product_Category__c, Product_Type__c, cgcloud__State__c, Image_url__c 
//                 FROM Product2 
//                 WHERE Id = :productId 
//                 AND Product_Category__c != null 
//                 AND Product_Type__c != null 
//                 LIMIT 1];
//     }
// }