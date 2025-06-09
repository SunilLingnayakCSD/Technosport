global class DeleteOldFilesBatch implements Schedulable {
    global void execute(SchedulableContext sc) {
        //DateTime twoMonthsAgo = System.now().addMonths(-2);
        DateTime tenDaysAgo = System.now().addDays(-10);


        // Step 1: Get old Visit Tasks
        List<Visit_Task__c> oldTasks = [
            SELECT Id
            FROM Visit_Task__c
            //WHERE CreatedDate <= :twoMonthsAgo
            WHERE CreatedDate = TODAY
        ];

        if (oldTasks.isEmpty()) return;

        Set<Id> visitTaskIds = new Set<Id>();
        for (Visit_Task__c task : oldTasks) {
            visitTaskIds.add(task.Id);
        }

        // Step 2: Get all ContentDocumentLinks to those tasks
        List<ContentDocumentLink> docLinks = [
            SELECT Id, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :visitTaskIds
        ];

        if (docLinks.isEmpty()) return;

        Set<Id> contentDocIds = new Set<Id>();
        for (ContentDocumentLink link : docLinks) {
            contentDocIds.add(link.ContentDocumentId);
        }

        // Step 3: Delete the ContentDocumentLinks
        delete docLinks;

        // Step 4: Now get remaining links for those ContentDocuments
        List<ContentDocumentLink> remainingLinks = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE ContentDocumentId IN :contentDocIds
        ];

        Set<Id> stillLinked = new Set<Id>();
        for (ContentDocumentLink l : remainingLinks) {
            stillLinked.add(l.ContentDocumentId);
        }

        // Step 5: Delete only ContentDocuments that are no longer linked
        List<ContentDocument> docsToDelete = new List<ContentDocument>();
        for (Id docId : contentDocIds) {
            if (!stillLinked.contains(docId)) {
                docsToDelete.add(new ContentDocument(Id = docId));
            }
        }

        if (!docsToDelete.isEmpty()) {
            delete docsToDelete;
        }
    }
}