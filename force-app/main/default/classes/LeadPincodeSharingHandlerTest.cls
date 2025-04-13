@isTest
public class LeadPincodeSharingHandlerTest {

    // Test case for handling Lead Before Insert with a single Distributor
    @isTest
    static void testHandleLeadBeforeInsert_SingleDistributor() {
        // Mock Distributor Account
        Account mockDistributor = new Account(
            Name = 'Distributor 1',
            ShippingPostalCode = '12345',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Distributor').getRecordTypeId()
        );
        insert mockDistributor;
        
        // Mock Lead
        Lead__c newLead = new Lead__c(
            Name = 'Test Lead 2',
            Address__PostalCode__s = '12345',
            Company__c = 'Test Company', // Required field
            Lead_Status__c = 'New', // Required field
            Email__c = 'test2@example.com' // Required field
        );
        
        // Mock SOQL query results
        List<Account> mockDistributorAccounts = new List<Account>{ mockDistributor };
        Test.setFixedSearchResults(new List<Id>{ mockDistributor.Id });
        
        Test.startTest();
        // Call the handleLeadBeforeInsert method
        LeadPincodeSharingHandler.handleLeadBeforeInsert(newLead);
        Test.stopTest();
        
        // Assert that the Lead is assigned to the Distributor Account
        System.assertEquals(mockDistributor.Id, newLead.Assigned_Distributor__c, 'Lead should be assigned to the Distributor Account');
    }

    // Test case for handling Lead Before Insert with multiple Distributors
    @isTest
    static void testHandleLeadBeforeInsert_MultipleDistributors() {
        // Mock Distributor Accounts
        Account mockDistributor1 = new Account(
            Name = 'Distributor 1',
            ShippingPostalCode = '12345',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Distributor').getRecordTypeId()
        );
        Account mockDistributor2 = new Account(
            Name = 'Distributor 2',
            ShippingPostalCode = '12345',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Distributor').getRecordTypeId()
        );
        insert new List<Account>{ mockDistributor1, mockDistributor2 };
        
        // Mock Lead
        Lead__c newLead = new Lead__c(
            Name = 'Test Lead 3',
            Address__PostalCode__s = '12345',
            Company__c = 'Test Company', // Required field
            Lead_Status__c = 'New', // Required field
            Email__c = 'test3@example.com' // Required field
        );
        
        // Mock SOQL query results
        List<Account> mockDistributorAccounts = new List<Account>{ mockDistributor1, mockDistributor2 };
        Test.setFixedSearchResults(new List<Id>{ mockDistributor1.Id, mockDistributor2.Id });
        
        Test.startTest();
        // Call the handleLeadBeforeInsert method
        LeadPincodeSharingHandler.handleLeadBeforeInsert(newLead);
        Test.stopTest();
        
        // Assert that the Lead is assigned to one of the Distributor Accounts
        System.assertNotEquals(null, newLead.Assigned_Distributor__c, 'Lead should be assigned to one of the Distributor Accounts');
    }

    // Test case for handling Lead Before Insert with no matching Distributor
    @isTest
    static void testHandleLeadBeforeInsert_NoDistributor() {
        // Mock Lead with a pincode that does not match any Distributor Account
        Lead__c newLead = new Lead__c(
            Name = 'Test Lead 4',
            Address__PostalCode__s = '67890',
            Company__c = 'Test Company', // Required field
            Lead_Status__c = 'New', // Required field
            Email__c = 'test4@example.com' // Required field
        );
        
        // Mock empty SOQL query results
        List<Account> mockDistributorAccounts = new List<Account>();
        Test.setFixedSearchResults(new List<Id>());
        
        Test.startTest();
        // Call the handleLeadBeforeInsert method
        LeadPincodeSharingHandler.handleLeadBeforeInsert(newLead);
        Test.stopTest();
        
        // Assert that the Lead is not assigned to any Distributor Account
        System.assertEquals(null, newLead.Assigned_Distributor__c, 'Lead should not be assigned to any Distributor Account');
    }

    // Test case for handling Lead After Insert (with distributor)
    @isTest
    static void testHandleLeadAfterInsert() {
        // Mock Distributor Account
        Account mockDistributor = new Account(
            Name = 'Distributor 1',
            ShippingPostalCode = '12345',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Distributor').getRecordTypeId()
        );
        insert mockDistributor;

        // Create a mock Contact associated with the Distributor Account
        Contact mockContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = mockDistributor.Id
        );
        insert mockContact;

        // Create a mock Portal User associated with the Contact
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'Community Distributor Access' LIMIT 1];
        User mockUser = new User(
            Alias = 'dist1',
            Email = 'dist1@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = portalProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'dist1mmmnmnmnm@test.com',
            ContactId = mockContact.Id // Associate the user with the contact
        );
        insert mockUser;

        // Create a Lead assigned to the Distributor
        Lead__c newLead = new Lead__c(
            Name = 'Test Lead 5',
            Address__PostalCode__s = '12345',
            Company__c = 'Test Company', // Required field
            Lead_Status__c = 'New', // Required field
            Email__c = 'test5@example.com', // Required field
            Assigned_Distributor__c = mockDistributor.Id // Assign the distributor
        );

        // Ensure that lead is inserted first
        insert newLead;

        Test.startTest();
        // Call the handleLeadAfterInsert method
        LeadPincodeSharingHandler.handleLeadAfterInsert(newLead);
        Test.stopTest();

        // Assert that the Lead Share record was created for the Distributor User
        Integer shareCount = [SELECT COUNT() FROM Lead__share WHERE ParentId = :newLead.Id];
        System.assertEquals(2, shareCount, 'Lead Share record should be created for the Distributor User');
    }

    // Test case for handling Lead After Insert with no Distributor
    @isTest
    static void testHandleLeadAfterInsert_NoDistributor() {
        // Mock Lead without an assigned Distributor
        Lead__c newLead = new Lead__c(
            Name = 'Test Lead 6',
            Address__PostalCode__s = '67890',
            Company__c = 'Test Company', // Required field
            Lead_Status__c = 'New', // Required field
            Email__c = 'test6@example.com' // Required field
        );
        insert newLead; // Insert lead to trigger after insert logic

        Test.startTest();
        // Call the handleLeadAfterInsert method
        LeadPincodeSharingHandler.handleLeadAfterInsert(newLead);
        Test.stopTest();

        // Ensure no Lead Share records are created for this lead
        Integer shareCount = [SELECT COUNT() FROM Lead__share WHERE ParentId = :newLead.Id];
        System.assertEquals(1, shareCount, 'No Lead Share records should be created');
    }
}