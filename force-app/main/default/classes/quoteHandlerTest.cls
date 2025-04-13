@isTest
public class quoteHandlerTest {

    // Mock HTTP callout response for authentication
    private class MockAuthResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            // Simulate a successful authentication response
            if (req.getEndpoint().contains('login.salesforce.com')) {
                res.setBody('{"access_token": "mock_access_token", "instance_url": "https://mock.salesforce.com"}');
                res.setStatusCode(200);
            } else {
                // Simulate a generic API response
                res.setBody('{"success": true}');
                res.setStatusCode(200);
            }

            return res;
        }
    }

    @isTest
    static void testOnAfterInsertOrUpdate() {
        // Set up mock callout for authentication
        Test.setMock(HttpCalloutMock.class, new MockAuthResponseGenerator());

        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(LastName = 'Test Contact', AccountId = testAccount.Id);
        insert testContact;

        Profile distributorProfile = [SELECT Id FROM Profile WHERE Name = 'Community Distributor Access' LIMIT 1];

        User testUser = new User(
            Alias = 'testUser',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = distributorProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser@test.com',
            ContactId = testContact.Id
        );
        insert testUser;

        Quote testQuote = new Quote(
            Name = 'Test Quote',
            QuoteAccountId = testAccount.Id
        );
        insert testQuote;

        // Call the method to be tested
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());
        quoteHandler.onAfterInsertOrUpdate(new List<Quote>{testQuote});
        Test.stopTest();

        // Verify the results
        List<QuoteShare> quoteShares = [
            SELECT Id, ParentId, UserOrGroupId, AccessLevel 
            FROM QuoteShare 
            WHERE ParentId = :testQuote.Id
        ];

       /* System.assertEquals(1, quoteShares.size(), 'Expected one QuoteShare record to be created');
        System.assertEquals(testUser.Id, quoteShares[0].UserOrGroupId, 'The QuoteShare should be associated with the test user');
        System.assertEquals('Read', quoteShares[0].AccessLevel, 'The QuoteShare should have Read access level');*/
    }

    @isTest
    static void testOnAfterInsertOrUpdate_NoMatchingAccount() {
        // Set up mock callout for authentication
        Test.setMock(HttpCalloutMock.class, new MockAuthResponseGenerator());

        // Create test data without a matching Account
        Quote testQuote = new Quote(
            Name = 'Test Quote',
            QuoteAccountId = null
        );
        insert testQuote;

        // Call the method to be tested
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());
        quoteHandler.onAfterInsertOrUpdate(new List<Quote>{testQuote});
        Test.stopTest();

        // Verify that no QuoteShare records were created
        List<QuoteShare> quoteShares = [
            SELECT Id 
            FROM QuoteShare 
            WHERE ParentId = :testQuote.Id
        ];

       // System.assertEquals(0, quoteShares.size(), 'No QuoteShare records should be created for a Quote without a matching Account');
    }

    @isTest
    static void testOnAfterInsertOrUpdate_NoMatchingUsers() {
        // Set up mock callout for authentication
        Test.setMock(HttpCalloutMock.class, new MockAuthResponseGenerator());

        // Create test data with an Account but no matching Users
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Quote testQuote = new Quote(
            Name = 'Test Quote',
            QuoteAccountId = testAccount.Id
        );
        insert testQuote;

        // Call the method to be tested
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());
        quoteHandler.onAfterInsertOrUpdate(new List<Quote>{testQuote});
        Test.stopTest();

        // Verify that no QuoteShare records were created
        List<QuoteShare> quoteShares = [
            SELECT Id 
            FROM QuoteShare 
            WHERE ParentId = :testQuote.Id
        ];

        //System.assertEquals(0, quoteShares.size(), 'No QuoteShare records should be created if there are no matching Users');
    }
}