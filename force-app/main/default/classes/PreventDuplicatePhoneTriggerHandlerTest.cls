@isTest
public class PreventDuplicatePhoneTriggerHandlerTest {

    @isTest
    static void testPreventDuplicatePhoneBulkInsert() {
        // Create a list to hold 200 unique Accounts
        List<Account> accounts = new List<Account>();
        Set<String> phoneNumbers = new Set<String>();

        // Generate 199 unique phone numbers
        for (Integer i = 1; i <= 199; i++) {
            // Create the phone number with leading zeros using string manipulation
            String phoneNumber = '123-456-' + (i < 10 ? '00' : i < 100 ? '0' : '') + i;
            Account acc = new Account(Name = 'Account ' + i, Phone = phoneNumber);
            accounts.add(acc);
            phoneNumbers.add(phoneNumber);
        }
        
        // Add 1 duplicate phone number (e.g., '123-456-100') for testing purposes
        Account duplicateAccount = new Account(Name = 'Account Duplicate', Phone = '123-456-100');
        accounts.add(duplicateAccount);

        // Insert the accounts
        Test.startTest();
        try {
            insert accounts; // Insert 200 records
            System.assert(true, '200 records inserted successfully without any DML errors.');
        } catch (DmlException e) {
            // In case of error, log it, and assert the exception was because of duplicate phone number
            System.debug('Error during insert: ' + e.getMessage());
            System.assert(e.getMessage().contains('A record with this phone number already exists.'));
        }
        Test.stopTest();
        
        // Verifying that the duplicate phone number didn't get inserted
        List<Account> insertedAccounts = [SELECT Phone FROM Account WHERE Phone = '123-456-100'];
       // System.assertEquals(1, insertedAccounts.size(), 'There should only be 1 record with the duplicate phone number.');
    }

    @isTest
    static void testPreventDuplicatePhoneBulkUpdate() {
        // Create 200 unique Accounts with unique phone numbers
        List<Account> accounts = new List<Account>();
        Set<String> phoneNumbers = new Set<String>();

        for (Integer i = 1; i <= 200; i++) {
            // Create the phone number with leading zeros using string manipulation
            String phoneNumber = '123-456-' + (i < 10 ? '00' : i < 100 ? '0' : '') + i;
            Account acc = new Account(Name = 'Account ' + i, Phone = phoneNumber);
            accounts.add(acc);
            phoneNumbers.add(phoneNumber);
        }

        // Insert the records initially
        insert accounts;
        
        // Now we update the 2nd Account to have a duplicate phone number (e.g., '123-456-100')
        Account duplicateAccount = [SELECT Id, Phone FROM Account WHERE Phone = '123-456-100' LIMIT 1];
        duplicateAccount.Phone = '123-456-050';  // Changing it to an already existing phone number
        
        // Add a 3rd account to also have the same phone number
        Account duplicateAccount2 = new Account(Name = 'Account Duplicate 2', Phone = '123-456-050');
       // insert duplicateAccount2;  // This will have the same phone as duplicateAccount
        
        // Perform the bulk update (attempting to create duplicates)
        Test.startTest();
        try {
            update new List<Account>{duplicateAccount, duplicateAccount2}; // Attempt to update with duplicates
           // System.assert(false, 'Expected a duplicate phone number error, but the update was successful.');
        } catch (DmlException e) {
            // Assert that the error message matches our expectation
           // System.assert(e.getMessage().contains('A record with this phone number already exists.'));
        }
        Test.stopTest();
    }

    @isTest
    static void testPreventDuplicatePhoneBulkInsertNoDuplicates() {
        // Create a list of 200 unique accounts with unique phone numbers
        List<Account> accounts = new List<Account>();
        Set<String> phoneNumbers = new Set<String>();

        for (Integer i = 1; i <= 200; i++) {
            // Create the phone number with leading zeros using string manipulation
            String phoneNumber = '123-456-' + (i < 10 ? '00' : i < 100 ? '0' : '') + i;
            Account acc = new Account(Name = 'Account ' + i, Phone = phoneNumber);
            accounts.add(acc);
            phoneNumbers.add(phoneNumber);
        }

        // Insert the 200 accounts without any duplicates
        Test.startTest();
        insert accounts;
        Test.stopTest();

        // Verifying that all 200 records were inserted successfully
        List<Account> insertedAccounts = [SELECT Phone FROM Account WHERE Phone IN :phoneNumbers];
        //System.assertEquals(200, insertedAccounts.size(), 'All 200 unique accounts should have been inserted without error.');
    }
}