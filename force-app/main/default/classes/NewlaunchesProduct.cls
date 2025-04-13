public class NewlaunchesProduct {
    @AuraEnabled(cacheable=true)
    public static List<Product2> getRecentProducts(Integer rowlimit,Integer offset) {
    
    Date lastWeekDate = System.today().addDays(-7);
    System.debug('lastWeekDate'+lastWeekDate);
    Pricebook2 standardPricebook = [
        SELECT Id
        FROM Pricebook2
        WHERE IsStandard = TRUE
        LIMIT 1
      ];
    String selectedPricebookId = standardPricebook.Id;
     System.debug('selectedPricebookId==='+selectedPricebookId);
   
    List<Product2> products = [
        SELECT Id, Name, Image_url__c, Video_Url__c, cgcloud__Category__c, CreatedDate,isActive,Boxes__c,Number_of_pieces_in_Box__c,GoogleDrive_Field__c,
               (SELECT Id, Product2Id, UnitPrice, Pricebook2Id FROM PricebookEntries  WHERE Pricebook2Id = :selectedPricebookId),(Select Id,Color__c,Variant_ExternalId__c,Size__c,isActive From Products1__r Where isActive=true)
        FROM Product2
        WHERE CreatedDate >= :lastWeekDate
        AND  isActive = true AND Product_Template__c=null
        ORDER BY CreatedDate DESC
        limit:rowlimit OFFSET:offset
    ];
    System.debug('products'+products);
    
    return products;
}
}