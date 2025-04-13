@isTest
public class DistributorControllerTest {

    // Helper method to create a test Distributor Account
    private static Account createDistributorAccount() {
        // Create a new Account with a RecordType DeveloperName as 'Distributor'
        RecordType distributorRecordType = [SELECT Id FROM RecordType WHERE DeveloperName = 'Distributor' LIMIT 1];
        
        Account testAccount = new Account(
            Name = 'Test Distributor Account',
            RecordTypeId = distributorRecordType.Id,
            Overdue_Threshold_Limit__c = 1000,
            Sales_Target__c = 50000
            
        );

        
        insert testAccount;
        return testAccount;
        
    }

    @isTest
    static void testGetDistributorAccounts() {
        // Create a test Account with RecordType 'Distributor'
        Account distributorAccount = createDistributorAccount();

        // Test the getDistributorAccounts method
        Test.startTest();
        List<Account> accounts = DistributorController.getDistributorAccounts();
        Test.stopTest();

        // Assert that we get the expected account back
        System.assertNotEquals(0, accounts.size(), 'There should be at least one distributor account');
        System.assertEquals(distributorAccount.Name, accounts[0].Name, 'The account name should match');
        System.assertEquals(distributorAccount.Overdue_Threshold_Limit__c, accounts[0].Overdue_Threshold_Limit__c, 'The overdue threshold limit should match');
    }

    @isTest
    static void testUpdateOverdueThreshold() {
        // Create a test Account with RecordType 'Distributor'
        Account distributorAccount = createDistributorAccount();
        
        // Test the updateOverdueThreshold method
        Test.startTest();
        DistributorController.updateOverdueThreshold(distributorAccount.Id, 2000);
        Test.stopTest();

        // Retrieve the updated Account and assert the value was updated
        Account updatedAccount = [SELECT Id, Overdue_Threshold_Limit__c FROM Account WHERE Id = :distributorAccount.Id LIMIT 1];
        System.assertEquals(2000, updatedAccount.Overdue_Threshold_Limit__c, 'The overdue threshold limit should be updated to 2000');
    }

    @isTest
    static void testUpdateSalesTarget() {
        // Create a test Account with RecordType 'Distributor'
        Account distributorAccount = createDistributorAccount();
        
        // Test the updateSalesTarget method
        Test.startTest();
        DistributorController.updateSalesTarget(distributorAccount.Id, 60000);
        Test.stopTest();

        // Retrieve the updated Account and assert the value was updated
        Account updatedAccount = [SELECT Id, Sales_Target__c FROM Account WHERE Id = :distributorAccount.Id LIMIT 1];
        System.assertEquals(60000, updatedAccount.Sales_Target__c, 'The sales target should be updated to 60000');
    }
}