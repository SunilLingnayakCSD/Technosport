public with sharing class UserProfileController {
    
    // Method to get user-related data (Orders, Quotations, Invoices)
    @AuraEnabled(cacheable=true)
    public static Map<String, List<SObject>> getUserProfileData(Id userId) {
        
        // Result map that will hold Orders, Quotations, and Invoices
        Map<String, List<SObject>> result = new Map<String, List<SObject>>();
        
        // Fetch Orders for the user (assuming there's an Order object and it's related to User)
        List<Order> orders = [SELECT Id, Name FROM Order ];
        result.put('orders', orders);
        
        // Fetch Quotations for the user (assuming a Quotation object exists and is related to User)
        List<Quote> quote = [SELECT Id, Name FROM Quote ];
        result.put('quote', quote);
        
        // Fetch Invoices for the user (assuming an Invoice object exists and is related to User)
        List<Invoice__c> invoices = [SELECT Id, Name FROM Invoice__c ];
        result.put('invoices', invoices);
        
        return result;
    }
}