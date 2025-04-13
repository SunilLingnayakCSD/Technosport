@isTest
public class DistributorProductInterestControllerTest {

    // Test method
    @isTest
    public static void testCreateOrUpdateDistributorProductInterest() {
        // Step 1: Create a test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Step 2: Create a test contact associated with the account
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;

        // Step 3: Create a test user with the contact
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = 'Community Distributor Access' LIMIT 1];
        User testUser = new User(
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = communityProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser@example.com',
            ContactId = testContact.Id // Associating the user with the test account
        );
        insert testUser;

        // Step 4: Simulate a ProductId to test with
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;

        // Step 5: Ensure the test user has access to the Account
       /* AccountShare testAccountShare = new AccountShare(
            AccountId = testAccount.Id,
            UserOrGroupId = testUser.Id,
            AccountAccessLevel = 'Read', // Giving the test user read access to the Account
            RowCause = 'Manual'
        );
        insert testAccountShare;*/

        // Step 6: Log in as the test user
        System.runAs(testUser) {
            // Step 7: Call the method
            String productId = testProduct.Id;
            String areYouInterested = 'Yes';
            
            // Call the method with the test data
            String resultId = DistributorProductInterestController.createOrUpdateDistributorProductInterest(productId, areYouInterested);
            
            // Step 8: Assertions to verify the behavior
            // Check if a new Distributor_Product_Interest__c record was created
            List<Distributor_Product_Interest__c> interestRecords = [
                SELECT Id, Product__c, Are_you_intrested_in_this_Product__c, Account__c 
                FROM Distributor_Product_Interest__c 
                WHERE Product__c = :productId 
                AND Account__c = :testAccount.Id
            ];
            
            // Assert that a new record was created
            System.assertEquals(1, interestRecords.size(), 'There should be 1 Distributor_Product_Interest__c record');
            System.assertEquals('Yes', interestRecords[0].Are_you_intrested_in_this_Product__c, 'Interest should be "Yes"');
        }
    }
}