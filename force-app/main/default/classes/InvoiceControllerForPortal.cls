public class InvoiceControllerForPortal {
    @AuraEnabled(cacheable=true)
    public static List<Invoice__c> getInvoicesForLoggedInUser() {
       
        String userEmail = UserInfo.getUserEmail();
        
        List<Contact> contacts = [
            SELECT AccountId FROM Contact WHERE Email = :userEmail LIMIT 1
        ];
        
        
        if (contacts.isEmpty()) {
            return new List<Invoice__c>();
        }
        
    
        Id accountId = contacts[0].AccountId;
        
        // Query for invoices related to the AccountId
        List<Invoice__c> invoices = [
    SELECT Id, Name, Residual_Amount__c,Due_Date__c,CreatedDate
    FROM Invoice__c
    WHERE Account__c = :accountId 
    AND Residual_Amount__c != 0
    ORDER BY CreatedDate ASC
];
        return invoices;
    }
}