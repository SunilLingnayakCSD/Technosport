public class quoteHandler {
    public static void onAfterInsertOrUpdate(List<Quote> records) {
        // List to hold QuoteShare records that will be inserted
        List<QuoteShare> sharesToInsert = new List<QuoteShare>();

        // Set to hold unique AccountIds from the inserted/updated quotes
        Set<Id> quoteAccountIds = new Set<Id>();

        // Collect AccountIds from the Quote records
        for (Quote quote : records) {
            if (quote.QuoteAccountId != null) {
                quoteAccountIds.add(quote.QuoteAccountId);
            }
        }

        // If there are any AccountIds to process
        if (!quoteAccountIds.isEmpty()) {
            // Query Users with the 'Community Distributor Access' profile and matching AccountId
            List<User> communityDistributorUsers = [
                SELECT Id, Contact.AccountId 
                FROM User 
                WHERE Profile.Name = 'Community Distributor Access' 
                  AND Contact.AccountId IN :quoteAccountIds
            ];

            // Map to store AccountId -> List of users that belong to that account
            Map<Id, List<User>> accountToUsersMap = new Map<Id, List<User>>();

            // Populate the map with users grouped by AccountId
            for (User user : communityDistributorUsers) {
                if (!accountToUsersMap.containsKey(user.Contact.AccountId)) {
                    accountToUsersMap.put(user.Contact.AccountId, new List<User>());
                }
                accountToUsersMap.get(user.Contact.AccountId).add(user);
            }

            // Loop through the Quote records to check for matching AccountId and share with users
            for (Quote quote : records) {
                if (quote.QuoteAccountId != null && accountToUsersMap.containsKey(quote.QuoteAccountId)) {
                    // Get the list of users for the AccountId associated with this Quote
                    List<User> usersForAccount = accountToUsersMap.get(quote.QuoteAccountId);

                    // Loop through users and create a QuoteShare record for each one
                    for (User user : usersForAccount) {
                        // Ensure we don't create duplicate shares
                        QuoteShare share = new QuoteShare();
                        share.ParentId = quote.Id;  // The Quote being shared
                        share.UserOrGroupId = user.Id;  // The user with access
                        share.AccessLevel = 'Read';  // Granting Read-only access
                        sharesToInsert.add(share);
                    }
                }
            }

            // Insert the QuoteShare records if any were created
            if (!sharesToInsert.isEmpty()) {
                try {
                    insert sharesToInsert;
                    System.debug('Inserted QuoteShare records: ' + sharesToInsert);
                } catch (DmlException e) {
                    System.debug('Error inserting QuoteShare records: ' + e.getMessage());
                }
            }
        }
    }
}