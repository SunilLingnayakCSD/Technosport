public class NewlaunchesProduct {
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getRecentProducts(Integer rowlimit,Integer offset) {
    
    Date lastWeekDate = System.today().addDays(-2);
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
            SELECT Id, Name, Image_url__c, Video_Url__c, cgcloud__Category__c, CreatedDate, isActive, Boxes__c, Number_of_pieces_in_Box__c, GoogleDrive_Field__c, Next_Available_Date__c, isFutureProduct__c, is_New_Launch_Product__c,
                (SELECT Id, Product2Id, UnitPrice, Pricebook2Id 
                 FROM PricebookEntries  
                 WHERE Pricebook2Id = :selectedPricebookId),
                (SELECT Id, Color__c, Variant_ExternalId__c, Size__c, isActive,
                    (SELECT Id, Free_Quantity__c FROM Inventories__r LIMIT 1)
                 FROM Products1__r 
                 WHERE isActive = true),
                (SELECT ContentDocumentId FROM ContentDocumentLinks)
            FROM Product2
            WHERE is_New_Launch_Product__c = true
                AND isActive = true 
                AND Product_Template__c = null 
                AND cgcloud__Category__c = 'CATALOUGE PRODUCT' 
                AND isFutureProduct__c = false
            ORDER BY CreatedDate DESC
            LIMIT :rowLimit OFFSET :offset
        ];
        Set<Id> docIds = new Set<Id>();
        for (Product2 p : products) {
            for (ContentDocumentLink cdl : p.ContentDocumentLinks) {
                docIds.add(cdl.ContentDocumentId);
            }
        }

        Map<Id, ContentVersion> contentVersionMap = new Map<Id, ContentVersion>();
        if (!docIds.isEmpty()) {
            for (ContentVersion cv : [
                SELECT ContentDocumentId, Id, Title, FileExtension, VersionData 
                FROM ContentVersion 
                WHERE ContentDocumentId IN :docIds AND FileExtension = 'pdf' AND IsLatest = true
            ]) {
                contentVersionMap.put(cv.ContentDocumentId, cv);
            }
        }
         List<Map<String, Object>> results = new List<Map<String, Object>>();
        for (Product2 p : products) {
            Map<String, Object> productMap = new Map<String, Object>();

            productMap.put('Id', p.Id);
            productMap.put('Name', p.Name);
            productMap.put('Image_url__c', p.Image_url__c);
            productMap.put('Video_Url__c', p.Video_Url__c);
            productMap.put('cgcloud__Category__c', p.cgcloud__Category__c);
            productMap.put('CreatedDate', p.CreatedDate);
            productMap.put('isActive', p.isActive);
            productMap.put('Boxes__c', p.Boxes__c);
            productMap.put('Number_of_pieces_in_Box__c', p.Number_of_pieces_in_Box__c);
            productMap.put('GoogleDrive_Field__c', p.GoogleDrive_Field__c);
            productMap.put('Next_Available_Date__c', p.Next_Available_Date__c);
            productMap.put('isFutureProduct__c', p.isFutureProduct__c);
            productMap.put('is_New_Launch_Product__c', p.is_New_Launch_Product__c);
            productMap.put('PricebookEntries', p.PricebookEntries);
            productMap.put('Products1__r', p.Products1__r);
            productMap.put('ContentDocumentLinks', p.ContentDocumentLinks);
            List<String> pdfUrls = new List<String>();
            for (ContentDocumentLink cdl : p.ContentDocumentLinks) {
                if (contentVersionMap.containsKey(cdl.ContentDocumentId)) {
                    pdfUrls.add('/distributor/sfc/servlet.shepherd/version/download/' + contentVersionMap.get(cdl.ContentDocumentId).Id);  //working
                  // pdfUrls.add('/distributor/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_PDF&versionId=' + contentVersionMap.get(cdl.ContentDocumentId).Id +'&operationContext=S1');
                   //pdfUrls.add('/distributor/sfc/servlet.shepherd/version/renditionDownload/'+ contentVersionMap.get(cdl.ContentDocumentId).Id+'?operationContext=S1');

//pdfUrls.add('/distributor/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_PDF&versionId=' + contentVersionMap.get(cdl.ContentDocumentId).Id + '&operationContext=S1');

                }
            }
            productMap.put('pdfUrls', pdfUrls);

            results.add(productMap);
        }
 System.debug('products'+results);
        return results;

}
}