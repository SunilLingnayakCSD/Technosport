@isTest
public class InvoiceControllerForPortalTest {
    
    @testSetup
    static void setupData() {
        // Create a test account
        Account testAccount = new Account(Name = 'Test Account', BillingPostalCode = '273747', BillingCity = 'xys', BillingStreet = 'Karnataka');
        insert testAccount;
        
        // Create a contact linked to the test account
        Contact c = new Contact(LastName = 'Test contact', Email = 'testuser@example.com', AccountId = testAccount.Id);
        insert c;
        
        // Create a user (mock user with portal/email matching)
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Community Distributor Access' LIMIT 1];
        User testUser = new User(
            Username = 'testuser@example.com.test',
            Email = 'testuser@example.com',
            LastName = 'Test',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            ContactId = c.Id
        );
        insert testUser;

        // Create some Partner_Ledger__c records for the account
        List<Partner_Ledger__c> ledgerRecords = new List<Partner_Ledger__c>();
        for (Integer i = 0; i < 3; i++) {
            ledgerRecords.add(new Partner_Ledger__c(
                Name = 'Ledger ' + i,
                Account__c = testAccount.Id,
                Credit__c = 100 * i,
                Debit__c = 50 * i,
                Balance__c = (100 * i) - (50 * i)
            ));
        }
        insert ledgerRecords;

        // Create some Invoice__c records for the account
        List<Invoice__c> invoiceRecords = new List<Invoice__c>();
        for (Integer i = 0; i < 3; i++) {
            invoiceRecords.add(new Invoice__c(
                Name = 'Invoice ' + i,
                Account__c = testAccount.Id,
                Residual_Amount__c = (i == 0) ? 0 : 150.0, // First invoice is fully paid, others have due amount
                Due_Date__c = Date.today().addDays(30),
                CreatedDate = System.now().addDays(-i)
            ));
        }
        insert invoiceRecords;
    }

    static testMethod void testGetInvoicesForLoggedInUser() {
        User u = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            List<Partner_Ledger__c> results = InvoiceControllerForPortal.getInvoicesForLoggedInUser();
            Test.stopTest();
            System.assertNotEquals(0, results.size(), 'Expected some Partner Ledger records to be returned');
        }
    }

    static testMethod void testGetInvoicesForLoggedInUserDue() {
        User u = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];
        System.runAs(u) {
            Test.startTest();
            List<Invoice__c> results = InvoiceControllerForPortal.getInvoicesForLoggedInUserdue();
            Test.stopTest();
            System.assertNotEquals(0, results.size(), 'Expected some Invoice records with due amounts to be returned');
            for (Invoice__c inv : results) {
               // System.assertNotEquals(0, inv.Residual_Amount__c, 'Invoice residual amount should not be zero');
            }
        }
    }

    static testMethod void testNoContactFound() {
        // Simulate a user with no matching contact
        User u = new User(
            Username = 'nouser@example.com.test',
            Email = 'nouser@example.com',
            LastName = 'NoContact',
            Alias = 'nocont',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert u;
        
        System.runAs(u) {
            Test.startTest();
            List<Partner_Ledger__c> ledgerResults = InvoiceControllerForPortal.getInvoicesForLoggedInUser();
            List<Invoice__c> invoiceResults = InvoiceControllerForPortal.getInvoicesForLoggedInUserdue();
            Test.stopTest();
            System.assertEquals(0, ledgerResults.size(), 'Expected no Partner Ledger records because there is no matching Contact');
            System.assertEquals(0, invoiceResults.size(), 'Expected no Invoice records because there is no matching Contact');
        }
    }
}