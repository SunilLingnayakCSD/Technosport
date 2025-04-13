public class accountOverdueThresholdController {
    @AuraEnabled
    public static void updateAllAccountsThreshold(Decimal overdueThreshold) {
        // Ensure overdueThreshold is a valid value
        if (overdueThreshold != null) {
            try {
                // Query the RecordTypeId for the 'Distributor' record type
                RecordType distributorRecordType = [
                    SELECT Id FROM RecordType 
                    WHERE SObjectType = 'Account' AND DeveloperName = 'Distributor' 
                    LIMIT 1
                ];

                // Check if the RecordTypeId was found
                if (distributorRecordType == null) {
                    throw new AuraHandledException('Distributor RecordType not found.');
                }

                // Query only the Distributor record type accounts with valid cgcloud__Account_Template__c values
                List<Account> accountsToUpdate = [
                    SELECT Id, cgcloud__Account_Template__c, Overdue_Threshold_Limit__c
                    FROM Account
                    WHERE cgcloud__Account_Template__c != '' AND cgcloud__Account_Template__c != NULL
                    AND RecordTypeId = :distributorRecordType.Id
                    LIMIT 200
                ];

                System.debug('Accounts to update: ' + accountsToUpdate.size());

                if (accountsToUpdate.isEmpty()) {
                    throw new AuraHandledException('No valid distributor accounts found to update.');
                }

                // Loop through and update the accounts
                for (Account acc : accountsToUpdate) {
                    System.debug('Updating account ID: ' + acc.Id + ', current threshold: ' + acc.Overdue_Threshold_Limit__c);
                    acc.Overdue_Threshold_Limit__c = overdueThreshold;
                    System.debug('New threshold for account ID: ' + acc.Id + ' set to: ' + acc.Overdue_Threshold_Limit__c);
                }

                // Perform the update
                update accountsToUpdate;
                System.debug('Successfully updated ' + accountsToUpdate.size() + ' accounts.');

            } catch (DmlException e) {
                // Specific error handling for DML exceptions
                System.debug('Error in DML operation: ' + e.getMessage());
                throw new AuraHandledException('Error in updating accounts: ' + e.getMessage());
            } catch (Exception e) {
                // General error handling
                System.debug('Unexpected error: ' + e.getMessage());
                throw new AuraHandledException('Error in updating accounts: ' + e.getMessage());
            }
        } else {
            throw new AuraHandledException('Invalid threshold value');
        }
    }
}