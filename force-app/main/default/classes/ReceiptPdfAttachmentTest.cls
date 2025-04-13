@isTest
public class ReceiptPdfAttachmentTest {
    
    @isTest
    static void testGenerateReceiptEstimatePdf() {
        
        // Step 1: Set up test data (mocking an entity)
        // Create a test record for the LinkedEntityId (we'll use an Account in this case)
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Invoice__c testInvoice = new Invoice__c(Name = 'Test Invoice',Account__c=testAccount.id);
        insert testInvoice;
        
        // Step 2: Create a ContentVersion record (this will automatically create a ContentDocument)
        ContentVersion contentVersion = new ContentVersion(
            Title = 'EWayBill-v1.pdf',
            PathOnClient = 'EWayBill-v1.pdf',
            VersionData = Blob.valueOf('This is the test PDF content.')  // Mock PDF content
        );
        insert contentVersion;
        
        // Step 3: Create a ContentDocumentLink record to link the ContentDocument to the Account
        ContentDocumentLink docLink = new ContentDocumentLink(
            LinkedEntityId = testInvoice.Id,
            ContentDocumentId = [Select Id,ContentDocumentId from ContentVersion where Id=:contentVersion.Id].ContentDocumentId,  // Use the ContentDocumentId from ContentVersion
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert docLink;
        
        // Step 4: Set up the test for the PageReference
        Test.startTest();
        
        // Call the method we're testing
        ReceiptPdfAttachment.generateReceiptEstimatePdf(testInvoice.Id);
        
        Test.stopTest();
        
        // Step 5: Assertions to verify the behavior
        
        // Ensure that a ContentVersion record was inserted
        List<ContentVersion> contentVersions = [SELECT Title, PathOnClient,ContentDocumentId, VersionData FROM ContentVersion WHERE Title LIKE 'EWayBill-%' AND PathOnClient LIKE 'EWayBill-%'];
        System.assertEquals(2, contentVersions.size(), 'Expected one ContentVersion record to be created.');
        
      
        // Ensure that a ContentDocumentLink was created and linked to the correct Account record
        List<ContentDocumentLink> docLinks = [SELECT LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :testInvoice.Id and ContentDocumentId=:contentVersions[0].ContentDocumentId];
        System.assertEquals(1, docLinks.size(), 'Expected one ContentDocumentLink to be created.');
        System.assertEquals(testInvoice.Id, docLinks[0].LinkedEntityId, 'The linked entity ID should match the Account ID.');
    }
     @isTest
    static void testGenerateReceiptEstimatePdfwithoutExist() {
        
        // Step 1: Set up test data (mocking an entity)
        // Create a test record for the LinkedEntityId (we'll use an Account in this case)
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Invoice__c testInvoice = new Invoice__c(Name = 'Test Invoice1323',Account__c=testAccount.id);
        insert testInvoice;
        // Step 4: Set up the test for the PageReference
        Test.startTest();
        
        // Call the method we're testing
        ReceiptPdfAttachment.generateReceiptEstimatePdf(testInvoice.Id);
        
        Test.stopTest();
        
        // Step 5: Assertions to verify the behavior
        
        // Ensure that a ContentVersion record was inserted
        List<ContentVersion> contentVersions = [SELECT Title, PathOnClient,ContentDocumentId, VersionData FROM ContentVersion WHERE Title LIKE 'EWayBill-%' AND PathOnClient LIKE 'EWayBill-%'];
        System.assertEquals(1, contentVersions.size(), 'Expected one ContentVersion record to be created.');
        
      
        // Ensure that a ContentDocumentLink was created and linked to the correct Account record
        List<ContentDocumentLink> docLinks = [SELECT LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :testInvoice.Id and ContentDocumentId=:contentVersions[0].ContentDocumentId];
        System.assertEquals(1, docLinks.size(), 'Expected one ContentDocumentLink to be created.');
        System.assertEquals(testInvoice.Id, docLinks[0].LinkedEntityId, 'The linked entity ID should match the Account ID.');
    }
     @isTest
    static void testGenerateReceiptEstimatePdfwithoutVersion() {
        
        // Step 1: Set up test data (mocking an entity)
        // Create a test record for the LinkedEntityId (we'll use an Account in this case)
       Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Invoice__c testInvoice = new Invoice__c(Name = 'Test Invoice1323',Account__c=testAccount.id);
        insert testInvoice;
        // Step 4: Set up the test for the PageReference
         ContentVersion contentVersion = new ContentVersion(
            Title = 'EWayBill-v.pdf',
            PathOnClient = 'EWayBill-v.pdf',
            VersionData = Blob.valueOf('This is the test PDF content.')  // Mock PDF content
        );
        insert contentVersion;
        
        // Step 3: Create a ContentDocumentLink record to link the ContentDocument to the Account
        ContentDocumentLink docLink = new ContentDocumentLink(
            LinkedEntityId = testInvoice.Id,
            ContentDocumentId = [Select Id,ContentDocumentId from ContentVersion where Id=:contentVersion.Id].ContentDocumentId,  // Use the ContentDocumentId from ContentVersion
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert docLink;
        Test.startTest();
        
        // Call the method we're testing
        ReceiptPdfAttachment.generateReceiptEstimatePdf(testInvoice.Id);
        
        Test.stopTest();
        
        // Step 5: Assertions to verify the behavior
        
        // Ensure that a ContentVersion record was inserted
        List<ContentVersion> contentVersions = [SELECT Title, PathOnClient,ContentDocumentId, VersionData FROM ContentVersion WHERE Title LIKE 'EWayBill-%' AND PathOnClient LIKE 'EWayBill-%'];
        System.assertEquals(2, contentVersions.size(), 'Expected one ContentVersion record to be created.');
        
      
        // Ensure that a ContentDocumentLink was created and linked to the correct Account record
        List<ContentDocumentLink> docLinks = [SELECT LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :testInvoice.Id and ContentDocumentId=:contentVersions[0].ContentDocumentId];
        System.assertEquals(1, docLinks.size(), 'Expected one ContentDocumentLink to be created.');
        System.assertEquals(testInvoice.Id, docLinks[0].LinkedEntityId, 'The linked entity ID should match the Account ID.');
    }
}