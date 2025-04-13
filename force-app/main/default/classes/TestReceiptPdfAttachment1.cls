@isTest
public class TestReceiptPdfAttachment1 {
    
    @isTest
    public static void testGenerateReceiptEstimatePdfWithExistingAttachments() {
        
        // Step 1: Create a mock Account (or any SObject you are using)
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Step 2: Create a mock ContentVersion (simulate existing attachment)
        ContentVersion existingContentVersion = new ContentVersion(
            Title = 'Invoice-v1.pdf',
            PathOnClient = 'Invoice-v1.pdf',
            VersionData = Blob.valueOf('Existing PDF content')
        );
        insert existingContentVersion;
        
        // Step 3: Create a ContentDocumentLink to link the ContentVersion to the Account
        ContentDocumentLink existingLink = new ContentDocumentLink(
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :existingContentVersion.Id LIMIT 1].ContentDocumentId,
            LinkedEntityId = testAccount.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert existingLink;

        // Step 4: Now we will call the method we want to test
        Test.startTest();
        ReceiptPdfAttachment1.generateReceiptEstimatePdf(testAccount.Id);
        Test.stopTest();

        // Step 5: Verify the results
        // Check if a new ContentVersion was created with the expected title
        ContentVersion newContentVersion = [SELECT Title, PathOnClient FROM ContentVersion WHERE Title LIKE 'Invoice-v%' AND PathOnClient LIKE 'Invoice-v%' ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals('Invoice-v1.pdf', newContentVersion.Title);
        System.assertEquals('Invoice-v1.pdf', newContentVersion.PathOnClient);
    }

    @isTest
    public static void testGenerateReceiptEstimatePdfWithoutExistingAttachments() {
        
        // Step 1: Create a mock Account (or any SObject you are using)
        Account testAccount = new Account(Name = 'Test Account No Attachments');
        insert testAccount;

        // Step 2: Now we will call the method we want to test
        Test.startTest();
        ReceiptPdfAttachment1.generateReceiptEstimatePdf(testAccount.Id);
        Test.stopTest();

        // Step 3: Verify the results
        // Check if a new ContentVersion was created with the expected title
        ContentVersion newContentVersion = [SELECT Title, PathOnClient FROM ContentVersion WHERE Title LIKE 'Invoice-v%' AND PathOnClient LIKE 'Invoice-v%' ORDER BY CreatedDate DESC LIMIT 1];
        System.assertEquals('Invoice-v1.pdf', newContentVersion.Title);
        System.assertEquals('Invoice-v1.pdf', newContentVersion.PathOnClient);
    }
}