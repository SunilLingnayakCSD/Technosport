public class VisitTaskAttachmentCleanup implements Schedulable {

    public void execute(SchedulableContext sc) {
        run();
    }

    public static void run() {
        DateTime twoMonthsAgo = System.now().addMonths(-2);

        List<Visit_Task__c> tasks = [
            SELECT Id FROM Visit_Task__c WHERE CreatedDate <= :twoMonthsAgo
        ];

        if (tasks.isEmpty()) {
            return;
        }

        Set<Id> taskIds = new Set<Id>();
        for (Visit_Task__c t : tasks) taskIds.add(t.Id);

        List<Attachment> atts = [
            SELECT Id
            FROM Attachment
            WHERE ParentId IN :taskIds
        ];
        if (!atts.isEmpty()) {
            delete atts;
        }

        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :taskIds
        ];

        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink l : links) docIds.add(l.ContentDocumentId);

        if (!docIds.isEmpty()) {
            List<ContentDocument> docs = [
                SELECT Id
                FROM ContentDocument
                WHERE Id IN :docIds
            ];
            delete docs;
        }
    }
}