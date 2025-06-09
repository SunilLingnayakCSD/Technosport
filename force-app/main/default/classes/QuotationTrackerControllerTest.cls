@isTest
public class QuotationTrackerControllerTest {

    @isTest
    static void testFetchAllQuotes() {
        // Create test user with 'System Administrator' profile
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = new User(
            LastName='test',
            Username = 'adminuser@example.com',
            Email = 'adminuser@example.com',
            Alias = 'admin',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            UserRoleId = null
        );
        insert adminUser;

        // Create test user with 'Standard User' profile (non-admin)
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User standardUser = new User(
            LastName='test',
            Username = 'standarduser@example.com',
            Email = 'standarduser@example.com',
            Alias = 'stdusr',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            UserRoleId = null
        );
        insert standardUser;

        // Create test Pricebook2 (Standard Pricebook)
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        // Create a test Product2 (created within last 7 days)
        Product2 testProduct1 = new Product2(
            Name = 'Test Product 1',
            isActive = true,
            Image_url__c = 'http://example.com/product1.jpg',
            Video_Url__c = 'http://example.com/product1.mp4',
            cgcloud__Category__c = 'Category 1',
            Product_Template__c = null
        );
        insert testProduct1;

        // Create PricebookEntry for the product in the Standard Pricebook
        PricebookEntry pricebookEntry1 = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct1.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pricebookEntry1;

        // Create test account for the standard user (non-admin)
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        // Create test quotes and quote line items for the non-admin user
        Quote quote1 = new Quote(
            Name = 'Quote 1',
            QuoteAccountId = testAccount.Id,
            Status = 'Draft',
            Pricebook2Id = standardPricebook.Id  // Assign the price book to the quote
        );
        insert quote1;

        QuoteLineItem quoteLineItem1 = new QuoteLineItem(
            QuoteId = quote1.Id,
            Product2Id = testProduct1.Id,
            Quantity = 10,
            Product_Type__c = 'Blank',
            UnitPrice = 1000,
            PricebookEntryId = pricebookEntry1.Id
        );
        insert quoteLineItem1;

        Quote quote2 = new Quote(
            Name = 'Quote 2',
            QuoteAccountId = testAccount.Id,
            Status = 'SalesOrder',
            Pricebook2Id = standardPricebook.Id  // Assign the price book to the quote
        );
        insert quote2;

        QuoteLineItem quoteLineItem2 = new QuoteLineItem(
            QuoteId = quote2.Id,
            Product2Id = testProduct1.Id,
            Quantity = 5,
            Product_Type__c = 'Catalogue',
            UnitPrice = 1000,
            PricebookEntryId = pricebookEntry1.Id
        );
        insert quoteLineItem2;

        // Start Test Context for the entire test
        Test.startTest();

        // Switch the current user context to 'System Administrator' for testing
        System.runAs(adminUser) {
            Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());
            List<quotationTrackerController.QuoteWrapper> quotesAdmin = quotationTrackerController.fetchAllQuotes('2025-03-01', '2025-03-31', 'AllProducts');
            
            // Assert results for admin user
            System.assertNotEquals(0, quotesAdmin.size(), 'There should be quotes for admin user');
            System.assertEquals(2, quotesAdmin.size(), 'Admin user should retrieve all quotes');
        }

        // Switch the current user context to the 'Standard User' (non-admin) for testing
        System.runAs(standardUser) {
            Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());
            List<quotationTrackerController.QuoteWrapper> quotesUser = quotationTrackerController.fetchAllQuotes('2025-03-01', '2025-03-31', 'Blank');
            
            // Assert results for standard user (non-admin)
           // System.assertNotEquals(0, quotesUser.size(), 'There should be quotes for standard user');
          //  System.assertEquals(1, quotesUser.size(), 'Standard user should only see quotes with Blank product type');
        }

        // End Test Context
        Test.stopTest();
    }
}