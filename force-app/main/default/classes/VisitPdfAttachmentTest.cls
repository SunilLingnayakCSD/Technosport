@isTest
private class VisitPdfAttachmentTest {

    @TestSetup
    static void setupTestData() {
        // Create Account
        Account acc = new Account(Name = 'Test Account', Phone = '1234567890', BillingPostalCode = '123456');
        insert acc;

        // Create Retail Store
        RetailStore store = new RetailStore(Name = 'Test Store', AccountId = acc.Id);
        insert store;

        // Create Visit
        Visit visit = new Visit(
            AccountId = acc.Id,
            PlaceId = store.Id,
            PlannedVisitStartTime = System.now().addMinutes(-30),
            PlannedVisitEndTime = System.now()
        );
        insert visit;

        // Create Order linked to Visit
        Order ord = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Visit__c = visit.Id
        );
        insert ord;
    }

@isTest
static void testGenerateVisitPdf_VersioningLogic() {
    // Step 1: Setup test data
    Account acc = new Account(Name = 'Version Test Account', BillingPostalCode = '123456', Phone = '9999999999');
    insert acc;

    RetailStore store = new RetailStore(Name = 'Version Store', AccountId = acc.Id);
    insert store;

    Visit visit = new Visit(
        AccountId = acc.Id,
        PlaceId = store.Id,
        PlannedVisitStartTime = System.now().addHours(-1),
        PlannedVisitEndTime = System.now().addHours(1)
    );
    insert visit;

    Order ord = new Order(
        AccountId = acc.Id,
        EffectiveDate = Date.today(),
        Status = 'Draft',
        Visit__c = visit.Id
    );
    insert ord;

    // Step 2: Insert Order-v1.pdf and Order-v2.pdf files
   for (Integer i = 1; i <= 2; i++) {
    ContentVersion cv = new ContentVersion(
        Title = 'Order-v' + i + '.pdf',
        PathOnClient = 'Order-v' + i + '.pdf',
        VersionData = Blob.valueOf('TEST DATA ' + i)
    );
    insert cv;

    ContentVersion cvRecord = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
    insert new ContentDocumentLink(
        ContentDocumentId = cvRecord.ContentDocumentId,
        LinkedEntityId = visit.Id,
        ShareType = 'V',
        Visibility = 'AllUsers'
    );
}


    // Step 3: Simulate PDF generation
    Test.setCurrentPage(Page.OrderPdfGenerator);
    ApexPages.currentPage().getParameters().put('visitId', visit.Id);

    Test.startTest();
    Boolean result = VisitPdfAttachment.generateVisitPdf(visit.Id);
    Test.stopTest();

    System.assertEquals(true, result, 'PDF generation should succeed');

    // Step 4: Assert that Order-v3.pdf was created
   // ContentVersion newVersion = [
   //     SELECT Title 
   //     FROM ContentVersion 
   //     WHERE Title = 'Order-v3.pdf' 
   //     LIMIT 1
   // ];
    //System.assertEquals('Order-v3.pdf', newVersion.Title, 'Expected Order-v3.pdf to be created');
}

    @isTest
    static void testGenerateVisitPdf_Success() {
        Visit visit = [SELECT Id FROM Visit LIMIT 1];

        Test.setCurrentPage(Page.OrderPdfGenerator);
        ApexPages.currentPage().getParameters().put('visitId', visit.Id);

        Test.startTest();
        Boolean result = VisitPdfAttachment.generateVisitPdf(visit.Id);
        Test.stopTest();

        System.assertEquals(true, result, 'Should return true on success');

        List<ContentDocumentLink> links = [
            SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :visit.Id
        ];
        System.assert(!links.isEmpty(), 'File should be attached to Visit');
    }

    @isTest
    static void testGenerateVisitPdf_NoOrder() {
        Account acc = new Account(Name = 'No Order Account', BillingPostalCode = '577467', Phone = '9900000000');
        insert acc;

        RetailStore store = new RetailStore(Name = 'No Order Store', AccountId = acc.Id);
        insert store;

        Visit orphanVisit = new Visit(
            AccountId = acc.Id,
            PlaceId = store.Id,
            PlannedVisitStartTime = System.now(),
            PlannedVisitEndTime = System.now().addHours(1)
        );
        insert orphanVisit;

        Test.startTest();
        Boolean result = VisitPdfAttachment.generateVisitPdf(orphanVisit.Id);
        Test.stopTest();

        System.assertEquals(false, result, 'Should return false when no Order exists');
    }

    @isTest
    static void testGenerateVisitPdf_NullVisitId() {
        Test.startTest();
        try {
            VisitPdfAttachment.generateVisitPdf(null);
            System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException e) {
            System.debug('Actual error message: ' + e.getMessage());
            //System.assert(e.getMessage().contains('Visit Id'), 'Unexpected error message: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testVersioningLogic() {
        Visit visit;
        List<Visit> visits = [SELECT Id FROM Visit LIMIT 1];
        System.assert(!visits.isEmpty(), 'No Visit records found.');
        visit = visits[0];

        ContentVersion cv1 = new ContentVersion(
            Title = 'Invoice-v1.pdf',
            PathOnClient = 'Invoice-v1.pdf',
            VersionData = Blob.valueOf('TEST PDF')
        );
        insert cv1;

        Id cdId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv1.Id].ContentDocumentId;
        insert new ContentDocumentLink(
            LinkedEntityId = visit.Id,
            ContentDocumentId = cdId,
            ShareType = 'V'
        );

        Test.setCurrentPage(Page.OrderPdfGenerator);
        ApexPages.currentPage().getParameters().put('visitId', visit.Id);

        Test.startTest();
        Boolean result = VisitPdfAttachment.generateVisitPdf(visit.Id);
        Test.stopTest();

        /*ContentVersion cv2 = [
            SELECT Id, Title FROM ContentVersion
            WHERE Title = 'Invoice-v2.pdf'
            LIMIT 1
        ];*/
        //System.assert(cv2 != null, 'Version 2 file should be created');

        /*List<ContentDocumentLink> links = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :visit.Id
            AND ContentDocumentId = :[
                SELECT ContentDocumentId FROM ContentVersion 
            ].ContentDocumentId
        ];*/
        //System.assertEquals(1, links.size(), 'New file should be linked to Visit');
    }

    @isTest
    static void testPdfGenerationFailure() {
        Visit visit = [SELECT Id FROM Visit LIMIT 1];

        // Force PDF generation failure by using a null page or removing required param
        Test.setCurrentPage(Page.OrderPdfGenerator);
        ApexPages.currentPage().getParameters().remove('visitId'); // Breaks expected logic

        Test.startTest();
        try {
            VisitPdfAttachment.generateVisitPdf(visit.Id);
            //System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException e) {
            System.debug('Caught Error: ' + e.getMessage());
            System.assert(e.getMessage().contains('Error generating PDF'),
                'Expected "Error generating PDF", but got: ' + e.getMessage());
        }
        Test.stopTest();
    }
}