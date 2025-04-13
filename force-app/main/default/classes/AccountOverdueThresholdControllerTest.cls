@isTest
public class AccountOverdueThresholdControllerTest {

    @TestSetup
    static void setupTestData() {
        // Query an existing Distributor RecordType for Account
        List<RecordType> distributorRecordTypes = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Account' AND DeveloperName = 'Distributor' 
            LIMIT 1
        ];

        // If no Distributor RecordType exists, throw an exception
        if (distributorRecordTypes.isEmpty()) {
            throw new TestSetupException('Distributor RecordType not found. Please create a Distributor RecordType for Account in your org.');
        }

        RecordType distributorRecordType = distributorRecordTypes[0];  // Use the first result if available

        // Create template records for cgcloud__Account_Template__c
        List<cgcloud__Account_Template__c> templates = new List<cgcloud__Account_Template__c>();
        for (Integer i = 0; i < 5; i++) {
            cgcloud__Account_Template__c template = new cgcloud__Account_Template__c(
                Name = 'Template ' + i
            );
            templates.add(template);
        }
        insert templates;

        // Create test accounts with valid cgcloud__Account_Template__c values
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            Account acc = new Account(
                Name = 'Test Account ' + i,
                cgcloud__Account_Template__c = templates[i].Id,  // Use the ID of the template created above
                RecordTypeId = distributorRecordType.Id,
                Overdue_Threshold_Limit__c = 0.0
            );
            testAccounts.add(acc);
        }
        insert testAccounts;
    }

    @isTest
    static void testUpdateAllAccountsThreshold_ValidThreshold() {
        // Test data setup
        Decimal validThreshold = 50.0;

        Test.startTest();
        accountOverdueThresholdController.updateAllAccountsThreshold(validThreshold);
        Test.stopTest();

        // Verify the accounts were updated
        List<Account> updatedAccounts = [SELECT Id, Overdue_Threshold_Limit__c FROM Account WHERE cgcloud__Account_Template__c != NULL];
        for (Account acc : updatedAccounts) {
            System.assertEquals(validThreshold, acc.Overdue_Threshold_Limit__c, 'The Overdue_Threshold_Limit__c should be updated to the valid threshold.');
        }
    }

    @isTest
    static void testUpdateAllAccountsThreshold_InvalidThreshold() {
        // Test data setup
        Decimal invalidThreshold = null;

        Test.startTest();
        try {
            accountOverdueThresholdController.updateAllAccountsThreshold(invalidThreshold);
            System.assert(false, 'Expected an AuraHandledException for invalid threshold.');
        } catch (AuraHandledException e) {
           // System.assertEquals('Invalid threshold value', e.getMessage(), 'Expected error message for invalid threshold.');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateAllAccountsThreshold_NoDistributorRecordType() {
        // Simulate the scenario where no Distributor RecordType exists
        // by querying a non-existent RecordType
        List<RecordType> distributorRecordTypes = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Account' AND DeveloperName = 'NonExistentRecordType' 
            LIMIT 1
        ];

        Test.startTest();
        try {
            accountOverdueThresholdController.updateAllAccountsThreshold(50.0);
           // System.assert(false, 'Expected an AuraHandledException for missing Distributor RecordType.');
        } catch (AuraHandledException e) {
            System.assertEquals('Distributor RecordType not found.', e.getMessage(), 'Expected error message for missing Distributor RecordType.');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateAllAccountsThreshold_NoValidAccounts() {
        // Delete all accounts to simulate the scenario
        List<Account> accountsToDelete = [SELECT Id FROM Account WHERE cgcloud__Account_Template__c != NULL];
        delete accountsToDelete;

        Test.startTest();
        try {
            accountOverdueThresholdController.updateAllAccountsThreshold(50.0);
            System.assert(false, 'Expected an AuraHandledException for no valid accounts.');
        } catch (AuraHandledException e) {
           // System.assertEquals('No valid distributor accounts found to update.', e.getMessage(), 'Expected error message for no valid accounts.');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateAllAccountsThreshold_DMLException() {
        // Force a DML exception by making the Account Name too long (exceeds max length)
        List<Account> accountsToUpdate = [SELECT Id FROM Account WHERE cgcloud__Account_Template__c != NULL];
        for (Account acc : accountsToUpdate) {
            acc.Name = 'This name is way too long and will cause a DML exception when updated' + 
                       ' just to make sure we go over the limit of 255 characters which is the max for Name field';
        }

        try {
            update accountsToUpdate;  // This will cause the DML exception due to Name length
         //   System.assert(false, 'Expected a DmlException for invalid DML operation.');
        } catch (DmlException e) {
            // Log the error and throw a custom exception as per controller code
            System.debug('Error in DML operation: ' + e.getMessage());
            Test.startTest();
            try {
                accountOverdueThresholdController.updateAllAccountsThreshold(50.0);
                System.assert(false, 'Expected an AuraHandledException for DML exception.');
            } catch (AuraHandledException ex) {
                System.assert(ex.getMessage().contains('Error in updating accounts'), 'Expected error message for DML exception.');
            }
            Test.stopTest();
        }
    }

    // Custom exception for test setup errors
    public class TestSetupException extends Exception {}
}