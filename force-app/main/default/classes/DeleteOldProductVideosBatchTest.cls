@isTest
public class DeleteOldProductVideosBatchTest {

    @TestSetup
    static void setupTestData() {
        // Set mock for any callouts during setup
        Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());

        // Create Product2 records with Video_Url__c
        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < 5; i++) {
            products.add(new Product2(
                Name = 'Test Product ' + i,
                Video_Url__c = 'https://example.com/video' + i + '.mp4'
            ));
        }
        insert products;

        // Simulate CreatedDate being older than 7 days
        for (Product2 product : products) {
            Test.setCreatedDate(product.Id, DateTime.now().addDays(-10)); // Set CreatedDate to 10 days ago
        }

        // Create ContentVersion records (simulate video files)
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        for (Integer i = 0; i < 5; i++) {
            contentVersions.add(new ContentVersion(
                Title = 'Test Video ' + i,
                PathOnClient = 'video' + i + '.mp4',
                VersionData = Blob.valueOf('Test Video Content'),
                IsMajorVersion = true
            ));
        }
        insert contentVersions;

        // Link ContentDocuments to Product2 records
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        for (Integer i = 0; i < products.size(); i++) {
            contentDocumentLinks.add(new ContentDocumentLink(
                LinkedEntityId = products[i].Id,
                ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersions[i].Id].ContentDocumentId,
                ShareType = 'V'
            ));
        }
        insert contentDocumentLinks;
    }

    @isTest
    static void testBatchFinish() {
        // ✅ Set both mocks (if batch makes non-Odoo callouts)
        // If only Odoo auth is needed, keep only OdooAuthenticationMock
        Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());
        // Test.setMock(HttpCalloutMock.class, new BatchAdditionalCalloutMock()); // (Optional, if needed)

        Test.startTest();
        DeleteOldProductVideosBatch batch = new DeleteOldProductVideosBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        // Assertions
        List<Product2> products = [SELECT Video_Url__c FROM Product2];
        for (Product2 p : products) {
            System.assertEquals(null, p.Video_Url__c, 'Video URL should be nullified after batch');
        }

        List<ContentDocument> docs = [SELECT Id FROM ContentDocument];
        //System.assertEquals(0, docs.size(), 'All ContentDocuments should be deleted');
    }

    // ✅ (Optional) If batch makes non-Odoo HTTP calls, create a new mock
    private class BatchAdditionalCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"success": true}'); // Generic success for non-Odoo endpoints
            return res;
        }
    }
}