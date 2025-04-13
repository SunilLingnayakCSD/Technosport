// public with sharing class DistributorController {
    
//     @AuraEnabled(cacheable=true)
//     public static List<Account> getDistributorAccounts() {
       
//         List<Account> distributors = [SELECT Id, Name, Overdue_Threshold_Limit__c
//                                       FROM Account 
//                                       WHERE RecordType.DeveloperName = 'Distributor'];
//         return distributors;
//     }
    
//     @AuraEnabled
//     public static void updateOverdueThreshold(String accountId, Decimal newLimit) {
        
//         Account acc = [SELECT Id, Overdue_Threshold_Limit__c FROM Account WHERE Id = :accountId LIMIT 1];
//         acc.Overdue_Threshold_Limit__c = newLimit;
//         update acc;
//     }
// }


public with sharing class DistributorController {

    @AuraEnabled(cacheable=true)
    public static List<Account> getDistributorAccounts() {
        // Query to get only Distributor record type Accounts
        List<Account> distributors = [SELECT Id, Name, Overdue_Threshold_Limit__c, Sales_Target__c
                                      FROM Account 
                                      WHERE RecordType.DeveloperName = 'Distributor'];
        return distributors;
    }
    
    @AuraEnabled
    public static void updateOverdueThreshold(String accountId, Decimal newLimit) {
        // Update overdue threshold limit for the selected account
        Account acc = [SELECT Id, Overdue_Threshold_Limit__c FROM Account WHERE Id = :accountId LIMIT 1];
        acc.Overdue_Threshold_Limit__c = newLimit;
        update acc;
    }
    
    @AuraEnabled
    public static void updateSalesTarget(String accountId, Decimal newSalesTarget) {
        // Update sales target for the selected account
        Account acc = [SELECT Id, Sales_Target__c FROM Account WHERE Id = :accountId LIMIT 1];
        acc.Sales_Target__c = newSalesTarget;
        update acc;
    }
}