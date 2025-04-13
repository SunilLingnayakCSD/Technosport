public class DistributorProductInterestController {
   @AuraEnabled
public static String createOrUpdateDistributorProductInterest(String productId, String areYouInterested) {
    // Debug logs to help debug
    System.debug('Received productId: ' + productId);
    System.debug('Received areYouInterested: ' + areYouInterested);

    // Step 1: Get the logged-in user's ID
    Id loggedInUserId = UserInfo.getUserId();
    System.debug('Logged-in User Id: ' + loggedInUserId);

    // Step 2: Retrieve the list of Accounts associated with the logged-in user
    List<Account> userAccounts = ProductController.getAccountsForLoggedInUser(loggedInUserId);

    if (userAccounts.isEmpty()) {
        System.debug('Logged-in user does not have an Account associated.');
        return null;
    }

    // Assume the first account from the list is the correct one
    Id userAccountId = userAccounts[0].Id;
    System.debug('User Account Id: ' + userAccountId);

    // Step 3: Query for existing Distributor_Product_Interest__c record
    List<Distributor_Product_Interest__c> existingRecords = [
        SELECT Id, Product__c, Are_you_intrested_in_this_Product__c
        FROM Distributor_Product_Interest__c 
        WHERE Product__c = :productId 
        AND Account__c = :userAccountId 
        LIMIT 1
    ];

    // Step 4: If no existing record, create a new one
    if (existingRecords.isEmpty()) {
        Distributor_Product_Interest__c newRecord = new Distributor_Product_Interest__c(
            Product__c = productId,
            Are_you_intrested_in_this_Product__c = areYouInterested,  // Directly use the value passed
            Account__c = userAccountId
        );
        
        insert newRecord;
        System.debug('Created new Distributor_Product_Interest__c record: ' + newRecord.Id);
        return newRecord.Id;  // Return the ID of the new record
    } else {
        // Record exists, update the existing record
        Distributor_Product_Interest__c existingRecord = existingRecords[0];
        existingRecord.Are_you_intrested_in_this_Product__c = areYouInterested;  // Directly update to 'Yes'/'No'

        update existingRecord;
        System.debug('Updated existing Distributor_Product_Interest__c record: ' + existingRecord.Id);
    }

    return null;  // Return null if no new record was created
}

}