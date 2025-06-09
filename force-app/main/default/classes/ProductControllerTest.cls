@isTest
public class ProductControllerTest {

    @isTest
    static void testGetProducts() {
        // Create test products
        Product2 product1 = new Product2(Name = 'Product 1', IsActive = true, Product_Template__c = null, cgcloud__Category__c = 'Category 1');
        Product2 product2 = new Product2(Name = 'Product 2', IsActive = true, Product_Template__c = null, cgcloud__Category__c = 'Category 2');
        insert new List<Product2>{ product1, product2 };

        // Create a Pricebook2 entry
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        PricebookEntry pricebookEntry1 = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = product1.Id, UnitPrice = 100, IsActive = true);
        PricebookEntry pricebookEntry2 = new PricebookEntry(Pricebook2Id = standardPricebook.Id, Product2Id = product2.Id, UnitPrice = 200, IsActive = true);
        insert new List<PricebookEntry>{ pricebookEntry1, pricebookEntry2 };

        // Prepare the inputs for the method
        String filterValue = 'ALL';
        String categoryValue = null;
        Integer limitSize = 10;
        Integer offset = 0;
        String catval=null;

        // Run the test
        Test.startTest();
        List<Product2> result = ProductController.getProducts(filterValue, categoryValue, limitSize, offset,false,catval);
        Test.stopTest();

        // Assert that the products are returned
        // System.assertNotEquals(0, result.size(), 'Products should be returned');
        // System.assertEquals(2, result.size(), 'Expected 2 products');
    }

    @isTest
    static void testGetAccountsForLoggedInUser() {
        // Create a test user
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser = new User(
            LastName = 'Test',
            FirstName = 'User',
            Username = 'testuser@77uuuuuexample.com',
            Email = 'testuser@example.com',
            Alias = 'testuser',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            UserRoleId = null
        );
        insert testUser;

        // Create an account and contact for the user
        Account account = new Account(Name = 'Test Account',BillingPostalCode='273747',BillingCity='xys',BillingStreet='Karnataka');
        insert account;

        Contact contact = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'testuser@example.com', AccountId = account.Id);
        insert contact;

        // Run the test method for getAccountsForLoggedInUser
        Test.startTest();
        List<Account> result = ProductController.getAccountsForLoggedInUser(testUser.Id);
        Test.stopTest();

        // Assert the result
        System.assertNotEquals(0, result.size(), 'There should be at least 1 account returned');
        System.assertEquals(account.Name, result[0].Name, 'Account name should match');
    }

    @isTest
    static void testUserCounts() {
                 Id accId = SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Distributor').getRecordTypeId();
        Account account = new Account(Name = 'Test Account',RecordTypeId=accId,BillingPostalCode='273747',BillingCity='xys',BillingStreet='Karnataka');
        insert account;
        Contact c=new Contact(LastName='Shanmukh',AccountId=account.Id);
        insert c;
        // Create a test user
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'Community Distributor Access' LIMIT 1];
        User testUser = new User(
            LastName = 'Test',
            FirstName = 'User',
            Username = 'testuser2@88example.com',
            Email = 'testuser2@example.com',
            Alias = 'ty2',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            UserRoleId = null,
            ContactId=c.Id
           
        );
        insert testUser;

        // Create an account and contact for the user


        Contact contact = new Contact(FirstName = 'Test', LastName = 'Contact', Email = 'testuser2@example.com', AccountId = account.Id);
        insert contact;

        // Create cases and leads related to the account
        Case case1 = new Case(AccountId = account.Id, Status = 'Resolved');
        Case case2 = new Case(AccountId = account.Id, Status = 'New');
        insert new List<Case>{ case1, case2 };

        Lead__c lead1 = new Lead__c(Assigned_Distributor__c = account.Id, Lead_Status__c = 'Converted',Company__c='test',Email__c='shanmukh@gmail.com',Address__PostalCode__s='273747',Address__City__s='KAR',Address__Street__s='Manyatha');
        Lead__c lead2 = new Lead__c(Assigned_Distributor__c = account.Id, Lead_Status__c = 'Unqualified',Company__c='Test2',Email__c='shanmukh@gmail.com',Address__PostalCode__s='273747',Address__City__s='KAR',Address__Street__s='Manyatha');
        insert new List<Lead__c>{ lead1, lead2 };

        // Run the test method for userCounts
        Test.startTest();
        List<AccountStatsWrapper> result = ProductController.userCounts(testUser.Id);
        Test.stopTest();

        // Assert the result
        System.assertNotEquals(0, result.size(), 'There should be results for user counts');
        System.assertEquals(1, result.size(), 'Only 1 account should be returned');
    }

    
}