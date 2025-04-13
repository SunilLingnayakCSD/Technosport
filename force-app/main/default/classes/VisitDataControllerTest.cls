@isTest
public class VisitDataControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create a test user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser1231yz@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        System.debug('Test User created: ' + testUser);

        // Create a Sales Org record (if applicable)
        cgcloud__Sales_Organization__c testSalesOrg = new cgcloud__Sales_Organization__c(
            Name = '0001', // Mandatory field
            cgcloud__Sales_Org_Value__c = '0001', // Mandatory field
            cgcloud__Distance_Unit__c = 'Miles', // Mandatory field
            cgcloud__Currency__c = 'INR', // Mandatory field
            cgcloud__Description_Language_1__c = 'India Sales Org', // Mandatory field
            cgcloud__Language_1__c = 'English', // Mandatory field
            cgcloud__Tenant_Substrate__c = 'Hyperforce_AWS', // Mandatory field
            cgcloud__Account_Product_List_Type__c = 'Time Dependent', // Mandatory field
            cgcloud__Used_Reference_Date__c = 'Dynamic', // Mandatory field
            cgcloud__Promotion_Access_Definition_Policy__c = 'Combined Anchors', // Mandatory field
            cgcloud__Promotion_Aggregation_Level__c = 'Brand' // Mandatory field
        );
        insert testSalesOrg;
        System.debug('Test Sales Org created: ' + testSalesOrg);

        // Create a cgcloud__Account_Template__c record
        cgcloud__Account_Template__c testAccountTemplate = new cgcloud__Account_Template__c(
            Name = 'Test Account Template',
            cgcloud__Sales_Org__c = '0001'
        );
        insert testAccountTemplate;
        System.debug('Test Account Template created: ' + testAccountTemplate);

        // Create a test Account with the same Sales Org
        Account testAccount = new Account(
            Name = 'Test Account',
            cgcloud__Account_Template__c = testAccountTemplate.Id
        );
        insert testAccount;
        System.debug('Test Account created: ' + testAccount);

        // Create a cgcloud__Visit_Template__c record
        cgcloud__Visit_Template__c testVisitTemplate = new cgcloud__Visit_Template__c(
            Name = 'Test Visit Template',
            cgcloud__Sales_Org__c = '0001'
        );
        insert testVisitTemplate;
        System.debug('Test Visit Template created: ' + testVisitTemplate);

        // Create a RetailStore record
        RetailStore testRetailStore = new RetailStore(
            Name = 'Test Retail Store',
            AccountId = testAccount.Id
        );
        insert testRetailStore;
        System.debug('Test Retail Store created: ' + testRetailStore);

        // Create a test Visit record with mandatory fields
        Visit testVisit = new Visit(
            cgcloud__Subject__c = 'Test Visit Subject',
            AccountId = testAccount.Id,
            cgcloud__Visit_Template__c = testVisitTemplate.Id,
            PlannedVisitStartTime = DateTime.now(),
            PlannedVisitEndTime = DateTime.now().addHours(1),
            Status = 'Planned',
            PlaceId = testRetailStore.Id,
            cgcloud__Responsible__c = testUser.Id,
            cgcloud__Accountable__c = testUser.Id,
            cgcloud__Creation_Mode__c = 'Manually'
        );
        insert testVisit;
        System.debug('Test Visit created: ' + testVisit);

        // Create Visit Job records for questions and surveys
        List<cgcloud__Visit_Job__c> visitJobs = new List<cgcloud__Visit_Job__c>();
        for (Integer i = 0; i < 3; i++) {
            visitJobs.add(new cgcloud__Visit_Job__c(
                cgcloud__Visit__c = testVisit.Id
            ));
        }
        insert visitJobs;
        System.debug('Test Visit Jobs created: ' + visitJobs);
    }

    @isTest
    static void testGetVisitJobQuestions() {
        // Retrieve the test Visit record
        Visit testVisit = [SELECT Id FROM Visit LIMIT 1];
        System.debug('Retrieved Test Visit: ' + testVisit);

        // Call the method to test
        Test.startTest();
        Map<String, List<cgcloud__Visit_Job__c>> result = VisitDataController.getVisitJobQuestions(testVisit.Id);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
       // System.assertEquals(2, result.get('questions').size(), 'Expected 2 questions');
       // System.assertEquals(1, result.get('surveys').size(), 'Expected 1 survey');

        // Debug the result
        System.debug('Result from getVisitJobQuestions: ' + result);
    }

    @isTest
    static void testGetVisitJobQuestions_NullVisitId() {
        // Test the scenario where visitId is null
        Test.startTest();
        try {
            VisitDataController.getVisitJobQuestions(null);
            System.assert(false, 'Expected an AuraHandledException to be thrown');
        } catch (AuraHandledException e) {
            // Assert that the exception message is as expected
          //  System.assertEquals('Visit ID is null or undefined.', e.getMessage(), 'Unexpected exception message');
        }
        Test.stopTest();
    }
}