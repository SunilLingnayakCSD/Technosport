global class CreatePublicLinksBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Query ContentDocumentLink where ContentDocumentId is not null and LinkedEntityId is not null
        // Use IN operator to fetch multiple records
        return Database.getQueryLocator([
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN (SELECT ContentDocumentId FROM ContentVersion WHERE ContentDocumentId != NULL)
            AND LinkedEntityId != NULL
        ]);
    }

    global void execute(Database.BatchableContext BC, List<ContentDocumentLink> scope) {
        List<Product2> productsToUpdate = new List<Product2>();

        for (ContentDocumentLink cdl : scope) {
            // Generate the public URL for each file
            String publicUrl = 'https://yourdomain.com/sfc/servlet.shepherd/document/download/' 
                               + cdl.ContentDocumentId + '?operationContext=F1';

            // Update Product2 records with the public URL
            productsToUpdate.add(new Product2(
                Id = cdl.LinkedEntityId,
                Image_url__c = publicUrl
            ));
        }

        // Update the Product2 records in batches
        if (!productsToUpdate.isEmpty()) {
            update productsToUpdate;
            System.debug('productsToUpdate'+productsToUpdate);
        }
    }

    global void finish(Database.BatchableContext BC) {
        // Optional: Send notification or perform additional processing after the batch completes
    }
}