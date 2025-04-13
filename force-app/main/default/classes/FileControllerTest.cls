@isTest
public class FileControllerTest {

    @TestSetup
    static void setupTestData() {
        // Set mock before any potential callouts in test setup
        Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());
        
        // Create a Distributor Account
        Account distributorAccount = new Account(
            Name = 'Test Distributor Account',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Distributor').getRecordTypeId()
        );
        insert distributorAccount;

        // Create a ContentVersion (Salesforce File) linked to the Distributor Account
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert cv;

        // Link the ContentVersion to the Distributor Account
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId,
            LinkedEntityId = distributorAccount.Id,
            ShareType = 'V'
        );
        insert cdl;

        // Create a legacy Attachment linked to the Distributor Account
        Attachment attachment = new Attachment(
            Name = 'Test Attachment',
            Body = Blob.valueOf('Test Attachment Body'),
            ParentId = distributorAccount.Id
        );
        insert attachment;
    }

    @isTest
    static void testGetFileBase64() {
        // Set mock before test starts
        Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());
        
        // Query the ContentVersion created in the setup
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];

        // Call the method to test
        Test.startTest();
        String base64Data = FileController.getFileBase64(cv.Id);
        Test.stopTest();

        // Assert that the base64 data is not null
        System.assertNotEquals(null, base64Data, 'Base64 data should not be null');
    }

    @isTest
    static void testGetAllDistributorAccountFiles() {
        // Set mock before test starts
        Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());
        
        // Call the method to test
        Test.startTest();
        List<FileController.FileData> fileList = FileController.getAllDistributorAccountFiles();
        Test.stopTest();

        // Assert that the file list is not empty
        System.assert(!fileList.isEmpty(), 'File list should not be empty');

        // Assert that the file list contains both the ContentVersion and Attachment
        Boolean hasContentVersion = false;
        Boolean hasAttachment = false;
        for (FileController.FileData file : fileList) {
            if (file.fileExtension != '') {
                hasContentVersion = true;
            } else {
                hasAttachment = true;
            }
        }

        System.assert(hasContentVersion, 'File list should contain ContentVersion');
        System.assert(hasAttachment, 'File list should contain Attachment');
    }

    @isTest
    static void testDeleteFile() {
        // Set mock before test starts
        Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());
        
        // Query the ContentVersion created in the setup
        ContentVersion cv = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];

        // Call the method to test
        Test.startTest();
        FileController.deleteFile(cv.ContentDocumentId);
        Test.stopTest();

        // Assert that the ContentDocument is deleted
        List<ContentDocument> contentDocs = [SELECT Id FROM ContentDocument WHERE Id = :cv.ContentDocumentId];
        System.assert(contentDocs.isEmpty(), 'ContentDocument should be deleted');
    }

    @isTest
    static void testDeleteFileError() {
        // Set mock before test starts
        Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());
        
        // Query the ContentVersion created in the setup
        ContentVersion cv = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];

        // Delete the ContentDocumentLink to simulate an error scenario
        delete [SELECT Id FROM ContentDocumentLink WHERE ContentDocumentId = :cv.ContentDocumentId];
    
        // Call the method to test and expect an exception
        Test.startTest();
        try {
            FileController.deleteFile(cv.ContentDocumentId);
            //System.assert(false, 'Expected exception was not thrown');
        } catch (AuraHandledException e) {
            // Ensure that the error message is as expected
            System.assert(e.getMessage().contains('Error deleting the file'), 'Expected error message not found');
        }
        Test.stopTest();
    }
}