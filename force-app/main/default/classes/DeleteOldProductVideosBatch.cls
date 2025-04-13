global class DeleteOldProductVideosBatch implements Database.Batchable<SObject> {

    global String query;
    global Date sevenDaysAgo;

    global DeleteOldProductVideosBatch() {
        sevenDaysAgo = System.today().addDays(-7);
        query = 'SELECT Id, CreatedDate, Video_Url__c FROM Product2 WHERE Video_Url__c != NULL AND CreatedDate <= :sevenDaysAgo';
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Product2> scope) {
    List<Product2> productsToUpdate = new List<Product2>();
    List<ContentDocumentLink> filesToDelete = new List<ContentDocumentLink>();

    // Step 1: Collect Product2 IDs
    Set<Id> productIds = new Set<Id>();
    for (Product2 product : scope) {
        if (product.Video_Url__c != null && product.CreatedDate <= System.today().addDays(-7)) {
            productIds.add(product.Id);
        }
    }

    // Step 2: Query ContentDocumentLink records for all Product2 records in the scope
    Map<Id, List<ContentDocumentLink>> productIdToContentDocumentLinks = new Map<Id, List<ContentDocumentLink>>();
    for (ContentDocumentLink docLink : [
        SELECT Id, ContentDocumentId, LinkedEntityId 
        FROM ContentDocumentLink 
        WHERE LinkedEntityId IN :productIds
    ]) {
        if (!productIdToContentDocumentLinks.containsKey(docLink.LinkedEntityId)) {
            productIdToContentDocumentLinks.put(docLink.LinkedEntityId, new List<ContentDocumentLink>());
        }
        productIdToContentDocumentLinks.get(docLink.LinkedEntityId).add(docLink);
    }

    // Step 3: Query ContentDocuments for all ContentDocumentLink records
    Set<Id> contentDocumentIds = new Set<Id>();
    for (List<ContentDocumentLink> docLinks : productIdToContentDocumentLinks.values()) {
        for (ContentDocumentLink docLink : docLinks) {
            contentDocumentIds.add(docLink.ContentDocumentId);
        }
    }

    Map<Id, ContentDocument> contentDocumentMap = new Map<Id, ContentDocument>([
        SELECT Id, FileType 
        FROM ContentDocument 
        WHERE Id IN :contentDocumentIds AND FileType = 'MP4'
    ]);

    // Step 4: Process Product2 records and collect updates/deletes
    for (Product2 product : scope) {
        if (product.Video_Url__c != null && product.CreatedDate <= System.today().addDays(-7)) {
            // Nullify the video URL in Product2
            product.Video_Url__c = null;
            productsToUpdate.add(product);

            // Retrieve ContentDocumentLink records for this product
            List<ContentDocumentLink> videoFiles = productIdToContentDocumentLinks.get(product.Id);
            if (videoFiles != null) {
                // Retrieve ContentDocuments associated with the ContentDocumentLink and filter by 'MP4' file type
                for (ContentDocumentLink docLink : videoFiles) {
                    if (contentDocumentMap.containsKey(docLink.ContentDocumentId)) {
                        filesToDelete.add(docLink);
                    }
                }
            }
        }
    }

    // Step 5: Update Product2 records if needed
    if (!productsToUpdate.isEmpty()) {
        update productsToUpdate;
    }

    // Step 6: Delete the associated video files (ContentDocumentLinks)
    if (!filesToDelete.isEmpty()) {
        delete filesToDelete;
    }
}
    global void finish(Database.BatchableContext BC) {
        System.debug('Batch Process Completed: Old Product Videos Deleted and URL Nullified');
    }
}