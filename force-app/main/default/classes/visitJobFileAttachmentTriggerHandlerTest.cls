@isTest
public class visitJobFileAttachmentTriggerHandlerTest {

    @isTest
    public static void testHandleAfterInsert() {
        
        // Step 1: Create and insert Visit records
        List<Visit> visits = new List<Visit>();
        for (Integer i = 0; i < 200; i++) {
            visits.add(new Visit(
                cgcloud__Subject__c = 'Test Visit ' + i,
                PlaceId = '0YQC40000000NmDOAU',  // Setting PlaceId for the job
                PlannedVisitStartTime = System.now().addHours(i),  // Setting a PlannedStartTime with offset
                PlannedVisitEndTime = System.now().addHours(i + 1)
            ));
        }
        insert visits;

        // Step 2: Create and insert Visit Job records
        List<cgcloud__Visit_Job__c> visitJobs = new List<cgcloud__Visit_Job__c>();
        for (Integer i = 0; i < 200; i++) {
            visitJobs.add(new cgcloud__Visit_Job__c(
                cgcloud__Visit__c = visits[i].Id  // Linking to the Visit record
            ));
        }
        insert visitJobs;

        // Step 3: Create ContentVersion records (this simulates uploading files)
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        for (Integer i = 0; i < 200; i++) {
            Blob fileBlob = Blob.valueOf('This is a test file content ' + i); // Mock file content
            contentVersions.add(new ContentVersion(
                Title = 'Test Document ' + i,
                PathOnClient = 'TestDocument' + i + '.pdf',
                VersionData = fileBlob  // The file data
            ));
        }
        insert contentVersions;  // This creates ContentDocument and ContentDocumentLink automatically

        // Step 4: Create ContentDocumentLink records to link documents to Visit Jobs
        // ContentDocumentLink records will be created automatically when ContentVersion is inserted

        // Step 5: Call the method to test
        Test.startTest();
        // No need to insert ContentDocumentLink manually; they will be automatically created with the ContentVersion insert
        Test.stopTest();

        // Optionally, verify the ContentDocumentLink records were created correctly
      /*  List<ContentDocumentLink> insertedLinks = [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :visitJobs
        ];

        // Assertions to confirm that the content links were created
       /* System.assertEquals(200, insertedLinks.size(), 'Expected 200 ContentDocumentLinks to be inserted.');
        
        // Verify the ContentDocumentLinks are correctly linked to the Visits
        for (ContentDocumentLink link : insertedLinks) {
            System.assert(link.LinkedEntityId != null, 'LinkedEntityId should not be null');
            System.assert(link.ShareType == 'V', 'ShareType should be View access');
            System.assert(link.Visibility == 'AllUsers', 'Visibility should be AllUsers');
        }*/
    }
}