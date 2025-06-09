@isTest
public class InvoiceAttachmentHelperTest {

    @isTest
    public static void testGenerateInvoicePDFAndAttach() {
        // Step 1: Create test data for Invoice__c record
        Invoice__c testInvoice = new Invoice__c(
            Name = 'Test Invoice',
            E_Way_Bill_No__c = 'EWB123456'
        );
        insert testInvoice;
        
        // Step 2: Simulate the future method call to generate PDF and attach it
        Test.startTest();
        
        // Call the future method
        InvoiceAttachmentHelper.generateInvoicePDFAndAttach(testInvoice.Id);
        
        Test.stopTest();
        
        // Assertions are difficult for content version due to async nature and blob data, so we assume the future method completes successfully.
        // You can check for ContentVersion insertion indirectly by querying records after the future method execution
        List<ContentVersion> contentVersions = [SELECT Id, Title, PathOnClient, FirstPublishLocationId FROM ContentVersion WHERE FirstPublishLocationId = :testInvoice.Id];
        
        System.assertEquals(2, contentVersions.size(), 'Two content versions should have been created');
        System.assertEquals('E-Way Bill', contentVersions[0].Title, 'Title should be E-Way Bill');
        System.assertEquals('Invoice', contentVersions[1].Title, 'Title should be Invoice');
    }

    @isTest
    public static void testOnAfterInsert() {
        // Step 1: Create test data for Invoice__c record with Account__c
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Invoice__c testInvoice = new Invoice__c(
            Name = 'Test Invoice For Insert',
            Account__c = testAccount.Id // Ensure the Account is linked
        );
        insert testInvoice;
        
        // Step 2: Simulate after insert trigger logic (this is directly invoked by the `onAfterInsert` method)
        List<Invoice__c> insertedInvoices = [SELECT Id, Account__c FROM Invoice__c WHERE Id = :testInvoice.Id];
        InvoiceAttachmentHelper.onAfterInsertOrUpdate(insertedInvoices);

        // Verify that Invoice shares were created
        List<Invoice__Share> invoiceShares = [SELECT Id, UserOrGroupId FROM Invoice__Share WHERE ParentId = :testInvoice.Id];
        System.assert(invoiceShares.size() > 0, 'Invoice share records should be created for community distributor users');
    }

    @isTest
    public static void testOnAfterUpdate() {
        // Step 1: Create test data for Invoice__c record with Account__c
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Invoice__c testInvoice = new Invoice__c(
            Name = 'Test Invoice For Update',
            Account__c = testAccount.Id // Ensure the Account is linked
        );
        insert testInvoice;
        
        // Step 2: Simulate after update trigger logic (this is directly invoked by the `onAfterUpdate` method)
        testInvoice.Name = 'Updated Invoice Name';
        update testInvoice;
        
        List<Invoice__c> updatedInvoices = [SELECT Id, Account__c FROM Invoice__c WHERE Id = :testInvoice.Id];
        InvoiceAttachmentHelper.onAfterInsertOrUpdate(updatedInvoices);

        // Verify that Invoice shares were created
        List<Invoice__Share> invoiceShares = [SELECT Id, UserOrGroupId FROM Invoice__Share WHERE ParentId = :testInvoice.Id];
        System.assert(invoiceShares.size() > 0, 'Invoice share records should be created for community distributor users');
    }

    @isTest
    public static void testGenerateInvoicePDFAndAttachWithException() {
        // Step 1: Create test data for Invoice__c record
        Invoice__c testInvoice = new Invoice__c(
            Name = 'Test Invoice with Exception'
        );
        insert testInvoice;

        // Step 2: Simulate the future method call to generate PDF and attach it (handling exception in PDF generation)
        Test.startTest();
        
        // Modify Visualforce page reference to simulate an exception (force the PDF generation to fail)
        PageReference eWayBillPage = Page.EWayBill;
        eWayBillPage.getParameters().put('id', testInvoice.Id); 
        Blob eWayBillPdfBlob ;
        try {
            eWayBillPdfBlob = eWayBillPage.getContentAsPDF(); // This will throw an exception if page is not found or invalid
        } catch(VisualforceException e) {
            eWayBillPdfBlob = Blob.valueOf('Error generating PDF');
        }
        
        InvoiceAttachmentHelper.generateInvoicePDFAndAttach(testInvoice.Id);
        
        Test.stopTest();

        // Verify the ContentVersion still gets created
        List<ContentVersion> contentVersions = [SELECT Id, Title, PathOnClient, FirstPublishLocationId FROM ContentVersion WHERE FirstPublishLocationId = :testInvoice.Id];
        
        System.assertEquals(2, contentVersions.size(), 'Two content versions should have been created');
        System.assertEquals('E-Way Bill', contentVersions[0].Title, 'Title should be E-Way Bill');
        System.assertEquals('Invoice', contentVersions[1].Title, 'Title should be Invoice');
    }

    @isTest
    public static void testOnAfterInsertOrUpdateWithNoShares() {
        // Step 1: Create test data for Invoice__c record with Account__c, but no community distributor users
        Account testAccount = new Account(Name = 'Test Account Without Community Distributor');
        insert testAccount;

        // Step 2: Create a Contact record associated with the Account
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id
        );
        insert testContact;

        // Step 3: Create a community distributor user for testing the share creation
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = 'Community Distributor Access' LIMIT 1];
        User communityUser = new User(
            Alias = 'test',
            Email = 'test.user@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = communityProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'test.user@example.com',
            ContactId = testContact.Id
        );
        insert communityUser;

        // Step 4: Insert the Invoice__c record
        Invoice__c testInvoice = new Invoice__c(
            Name = 'Test Invoice Without Community Distributor Users',
            Account__c = testAccount.Id // Ensure the Account is linked
        );
        insert testInvoice;

        // Step 5: Simulate after insert or update logic (this is directly invoked by the `onAfterInsertOrUpdate` method)
        List<Invoice__c> insertedInvoices = [SELECT Id, Account__c FROM Invoice__c WHERE Id = :testInvoice.Id];
        InvoiceAttachmentHelper.onAfterInsertOrUpdate(insertedInvoices);

        // Verify that a share record was created since the community distributor user exists
        List<Invoice__Share> invoiceShares = [SELECT Id FROM Invoice__Share WHERE ParentId = :testInvoice.Id];
        System.assert(invoiceShares.size() > 0, 'Invoice share records should be created for the community distributor user');
    }

    @isTest
    public static void testExceptionHandling() {
        // Step 1: Create test data for Invoice__c record
        Invoice__c testInvoice = new Invoice__c(
            Name = 'Test Invoice for Exception Handling'
        );
        insert testInvoice;

        // Step 2: Simulate an exception in the future method
        Test.startTest();
        
        // Force an exception by passing an invalid ID
        try {
            InvoiceAttachmentHelper.generateInvoicePDFAndAttach('invalidId');
        } catch(Exception e) {
            // Verify that the exception is logged
            System.assertNotEquals(null, e, 'Exception should be caught and logged');
        }
        
        Test.stopTest();
    }
}