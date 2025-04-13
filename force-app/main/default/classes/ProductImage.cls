// public class ProductImage {
//  @AuraEnabled(cacheable=true)
//     public static List<Product2> product(Id recordId) { 
//         System.debug('Fetching: ' + recordId);  
//         if (String.isBlank(recordId)) {
//             throw new AuraHandledException('Record ID cannot be blank');
//         }
//         return [SELECT Id, Name, Image_URL__c,	Image__c, Product_Category__c, Product_Type__c, cgcloud__State__c 
//                             FROM Product2 WHERE Id = :recordId LIMIT 1];
// }

// }


public class ProductImage {
    @AuraEnabled(cacheable=true)
    public static List<Product2> product(Id recordId) { 
        System.debug('Fetching: ' + recordId);  
        if (String.isBlank(recordId)) {
            throw new AuraHandledException('Record ID cannot be blank');
        }

        return [SELECT Id, Name, Image_URL__c, Product_Category__c, Product_Type__c, cgcloud__State__c, IsActive, URL__c,GoogleDrive_Field__c
                FROM Product2 
                WHERE Id = :recordId 
                LIMIT 1];
    }
}