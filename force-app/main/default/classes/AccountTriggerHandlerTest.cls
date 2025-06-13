@isTest
public class AccountTriggerHandlerTest {

    @isTest
    public static void testHandleAccountSharing() {
        // Create a valid profile to associate with the test user
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Create test users
        User testUser = new User(
            Alias = 'tuser',
            Email = 'testuser@example.com',
            LastName='testuserz',
            Username = 'testusersdxc@example.com',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ContactId = null
        );
        insert testUser;
        
        // Create test Accounts with RecordType 'Distributor'
        RecordType distributorRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Distributor' AND SObjectType = 'Account' LIMIT 1];
        
        Account testAccount1 = new Account(
            Name = 'Test Account 1',
            RecordTypeId = distributorRecordType.Id
        );
        insert testAccount1;
        
        Account testAccount2 = new Account(
            Name = 'Test Account 2',
            RecordTypeId = distributorRecordType.Id
        );
        insert testAccount2;

        // Create test Contact linked to the Accounts
        Contact testContact1 = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            AccountId = testAccount1.Id
        );
        insert testContact1;

        Contact testContact2 = new Contact(
            FirstName = 'Jane',
            LastName = 'Doe',
            AccountId = testAccount2.Id
        );
        insert testContact2;

        // Create test Contact User associated with the Contacts
        User contactUser1 = new User(
            Alias = 'cusr1',
            Email = 'cusr1@example.com',
            Username = 'cusr1sd@example.com',
            LastName='cusr1',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert contactUser1;

        User contactUser2 = new User(
            Alias = 'cusr2',
            Email = 'cusr2@example.com',
            Username = 'cusr2zsd@example.com',
             LastName='cusr2',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert contactUser2;

        // Test the AccountSharing handler method
        Test.startTest();
        List<Account> accountsToProcess = [SELECT Id, RecordType.DeveloperName FROM Account WHERE Id IN :new Set<Id>{testAccount1.Id, testAccount2.Id}];
        AccountTriggerHandler.handleAccountSharing(accountsToProcess);
        Test.stopTest();

        // Verify AccountShare records are created
        List<AccountShare> shares = [SELECT Id, AccountId, UserOrGroupId, RowCause FROM AccountShare WHERE AccountId IN :new Set<Id>{testAccount1.Id, testAccount2.Id}];
        
        // Assert that sharing records exist
        System.assertEquals(2, shares.size(), 'There should be two AccountShare records created.');
        for (AccountShare share : shares) {
            //System.assertEquals(testUser.Id, share.UserOrGroupId, 'The AccountShare should be associated with the test user.');
            //System.assertEquals(Schema.AccountShare.RowCause.Manual, share.RowCause, 'The sharing reason should be Manual.');
        }
    }

   /* @isTest
    public static void testNoAccountSharingForNonDistributorRecordType() {
        // Create a valid profile to associate with the test user
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        // Create test Account without 'Distributor' RecordType
        RecordType standardRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Standard' AND SObjectType = 'Account' LIMIT 1];
        
        Account testAccount = new Account(
            Name = 'Test Account Standard',
            RecordTypeId = standardRecordType.Id
        );
        insert testAccount;
        
        // Create test Contact
        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            AccountId = testAccount.Id
        );
        insert testContact;

        // Create test User associated with the Contact
        User contactUser = new User(
            Alias = 'cusr',
            Email = 'cusr@example.com',
            Username = 'cusr@example.com',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ContactId = testContact.Id
        );
        insert contactUser;

        // Test the AccountSharing handler method
        Test.startTest();
        List<Account> accountsToProcess = [SELECT Id, RecordType.DeveloperName FROM Account WHERE Id = :testAccount.Id];
        AccountTriggerHandler.handleAccountSharing(accountsToProcess);
        Test.stopTest();

        // Verify that no sharing records are created for non-Distributor Account
        List<AccountShare> shares = [SELECT Id FROM AccountShare WHERE AccountId = :testAccount.Id];
        
        // Assert that no sharing records were created
        System.assertEquals(0, shares.size(), 'No AccountShare record should be created for non-Distributor Account.');
    }*/
}