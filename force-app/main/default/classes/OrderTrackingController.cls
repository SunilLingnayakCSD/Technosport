public with sharing class OrderTrackingController {

    @AuraEnabled(cacheable=true)
    public static List<AggregateResult> getMostFrequentOrders() {
        // Get the current user's AccountId and Profile Name
        User currentUser = [SELECT AccountId, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Id currentUserAccountId = currentUser.AccountId;
        System.debug('currentUserAccountId ' + currentUserAccountId );
        String currentUserProfileName = currentUser.Profile.Name;
        System.debug('currentUserProfileName ' + currentUserProfileName );

        // Check if the user is an admin by profile name (no hardcoding)
        boolean isAdmin = currentUserProfileName == 'System Administrator';  // Customize this profile name if needed
        
        List<AggregateResult> results;

        if (isAdmin) {
            // Query for Admin users: no restriction on AccountId
            results = [SELECT Product2Id, SUM(Quantity) totalQuantity
                       FROM OrderItem 
                       GROUP BY Product2Id
                       ORDER BY SUM(Quantity) DESC
                       LIMIT 10];
        } else {
            // Query for non-Admin users: restrict to orders linked to their account
            results = [SELECT Product2Id, SUM(Quantity) totalQuantity
                       FROM OrderItem 
                       WHERE Order.AccountId = :currentUserAccountId
                       GROUP BY Product2Id
                       ORDER BY SUM(Quantity) DESC
                       LIMIT 10];
        }

        return results;
    }

    @AuraEnabled(cacheable=true)
    public static List<Product2> getProductNames(List<Id> productIds) {
        // Query Product2 records by their Id to get the Product Name
        return [SELECT Id, Name FROM Product2 WHERE Id IN :productIds];
    }
}