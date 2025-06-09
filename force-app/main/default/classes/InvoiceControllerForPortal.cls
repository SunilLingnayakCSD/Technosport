public class InvoiceControllerForPortal {
    @AuraEnabled(cacheable=true)
    public static List<Partner_Ledger__c> getInvoicesForLoggedInUser() {
       
        String userEmail = UserInfo.getUserEmail();
        
        List<Contact> contacts = [
            SELECT AccountId FROM Contact WHERE Email = :userEmail LIMIT 1
        ];
        
        
        if (contacts.isEmpty()) {
            return new List<Partner_Ledger__c>();
        }
        
    
        Id accountId = contacts[0].AccountId;
        
       
        List<Partner_Ledger__c> ledgers = [
    SELECT Id, Name,Credit__c,Debit__c,Balance__c,CreatedDate,Ledger_Name__c
    FROM Partner_Ledger__c
    WHERE Account__c = :accountId 
    ORDER BY CreatedDate ASC
];
        return ledgers;
    }
        @AuraEnabled(cacheable=true)
    public static List<Invoice__c> getInvoicesForLoggedInUserdue() {
        String userEmail = UserInfo.getUserEmail();
        
        List<Contact> contacts = [
            SELECT AccountId FROM Contact WHERE Email = :userEmail LIMIT 1
        ];
        
        
        if (contacts.isEmpty()) {
            return new List<Invoice__c>();
        }
        Id accountId = contacts[0].AccountId;
        List<Invoice__c> invoices = [
    
    SELECT Id, Name, Residual_Amount__c,Due_Date__c,CreatedDate
    FROM Invoice__c
    WHERE Account__c = :accountId 
 
    ORDER BY CreatedDate ASC limit 1
];
        System.debug('invoices'+invoices);
        return invoices;
    
        
    }
    
}