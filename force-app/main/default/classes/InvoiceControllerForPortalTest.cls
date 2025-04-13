@isTest
public class InvoiceControllerForPortalTest {

    @isTest
    static void testGetInvoicesForLoggedInUser() {
        // Create a test user with a specific email
        String testEmail = 'testuser@example.com';
        
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User testUser = new User(
            Alias = 'testuser',
            LastName='shsh',
            Email = testEmail,
            ProfileId = testProfile.Id,
            Username = 'shjhjsj@jmk.com',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert testUser;
        
        // Run the test as the test user
        System.runAs(testUser) {
            // Create a test account
            Account testAccount = new Account(Name = 'Test Account');
            insert testAccount;
            
            // Create a test contact associated with the account and the same email as the user
            Contact testContact = new Contact(
                FirstName = 'Test',
                LastName = 'User',
                Email = testEmail,
                AccountId = testAccount.Id
            );
            insert testContact;
            
            // Create a test invoice related to the account
            Invoice__c testInvoice = new Invoice__c(
                Name = 'Test Invoice',
                Account__c = testAccount.Id,
                Residual_Amount__c = 100.00,
                Due_Date__c = System.today().addDays(30)

            );
            insert testInvoice;
            
            // Create a test invoice with residual amount 0 (this should not be returned)
            Invoice__c testInvoiceZeroResidual = new Invoice__c(
                Name = 'Test Invoice Zero Residual',
                Account__c = testAccount.Id,
                Residual_Amount__c = 0.00,
                Due_Date__c = System.today().addDays(30)
                
            );
            insert testInvoiceZeroResidual;

            // Call the method to get invoices for the logged-in user
            Test.startTest();
            List<Invoice__c> invoices = InvoiceControllerForPortal.getInvoicesForLoggedInUser();
            Test.stopTest();

            // Assert that the returned invoices list contains only the invoice with residual amount not equal to 0
            System.assertEquals(1, invoices.size());
            System.assertEquals(testInvoice.Id, invoices[0].Id);
            System.assertNotEquals(0, invoices[0].Residual_Amount__c); // Ensure the invoice has a non-zero residual amount
        }
    }
}