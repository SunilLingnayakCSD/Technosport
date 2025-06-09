public class visitJobFileAttachmentTriggerHandler {

    public static void handleAfterInsert(List<ContentDocumentLink> contentDocLinks) {
       
        try {
            
            System.debug(LoggingLevel.INFO, 'Starting the processing of ContentDocumentLinks: ' + contentDocLinks);

            // Collect all Visit Job IDs from the ContentDocumentLinks
            Set<Id> visitJobIds = new Set<Id>();

            for (ContentDocumentLink link : contentDocLinks) {
                // Debug statement for each link being processed
                System.debug(LoggingLevel.INFO, 'Processing ContentDocumentLink: ' + link);

                if (link.LinkedEntityId != null && link.LinkedEntityId.getSObjectType() == cgcloud__Visit_Job__c.sObjectType) {
                    visitJobIds.add(link.LinkedEntityId);
                }
            }

            // If there are no Visit Job IDs to process, exit early
            if (visitJobIds.isEmpty()) {
                System.debug(LoggingLevel.INFO, 'No valid Visit Job IDs found to process.');
                return;
            }

            // Query the Visit Jobs in bulk
            List<cgcloud__Visit_Job__c> visitJobs = [SELECT Id, cgcloud__Visit__c FROM cgcloud__Visit_Job__c WHERE Id IN :visitJobIds];

            // Debug statement for the fetched Visit Jobs
            System.debug(LoggingLevel.INFO, 'Fetched Visit Jobs: ' + visitJobs);

            // Create a map to quickly access Visit Jobs by their Id
            Map<Id, cgcloud__Visit_Job__c> visitJobMap = new Map<Id, cgcloud__Visit_Job__c>();
            for (cgcloud__Visit_Job__c visitJob : visitJobs) {
                visitJobMap.put(visitJob.Id, visitJob);
            }

            // Prepare a list of ContentDocumentLinks to insert
            List<ContentDocumentLink> visitDocLinksToInsert = new List<ContentDocumentLink>();

            for (ContentDocumentLink link : contentDocLinks) {
                // Check if the ContentDocumentLink is associated with a valid Visit Job
                if (link.LinkedEntityId != null && visitJobMap.containsKey(link.LinkedEntityId)) {
                    cgcloud__Visit_Job__c visitJob = visitJobMap.get(link.LinkedEntityId);

                    // Check if the Visit Job has a related Visit
                    if (visitJob != null && visitJob.cgcloud__Visit__c != null) {
                        // Create a new ContentDocumentLink to attach the file to the related Visit record
                        ContentDocumentLink newLink = new ContentDocumentLink(
                            ContentDocumentId = link.ContentDocumentId,
                            LinkedEntityId = visitJob.cgcloud__Visit__c,  // Link to the Visit record
                            ShareType = 'V',  // 'V' for View access
                            Visibility = 'AllUsers'  // Visibility: All users can see the file
                        );
                        visitDocLinksToInsert.add(newLink);
                    }
                }
            }

            // Debug statement before inserting ContentDocumentLinks
            System.debug(LoggingLevel.INFO, 'ContentDocumentLinks to insert: ' + visitDocLinksToInsert);

            // Insert the new ContentDocumentLinks if any were created
            if (!visitDocLinksToInsert.isEmpty()) {
                insert visitDocLinksToInsert;
                System.debug(LoggingLevel.INFO, 'Successfully inserted ContentDocumentLinks.');
            } else {
                System.debug(LoggingLevel.INFO, 'No ContentDocumentLinks were created for insertion.');
            }

        } catch (Exception e) {
         
            System.debug(LoggingLevel.ERROR, 'An error occurred in handleAfterInsert: ' + e.getMessage());
            
            
        }
    }
}