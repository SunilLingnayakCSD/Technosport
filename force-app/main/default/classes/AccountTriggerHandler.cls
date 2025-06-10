public class AccountTriggerHandler {

    // Method to handle sharing of Account records
    public static void handleAccountSharing(List<Account> accountsToProcess) {
        List<AccountShare> sharesToInsert = new List<AccountShare>();

        // Get the logged-in user's ID
        Id loggedInUserId = UserInfo.getUserId();

        // Collect Account IDs
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accountsToProcess) {
            if (acc.RecordType.DeveloperName == 'Distributor') {
                accountIds.add(acc.Id);
            }
        }
// Query all Contacts associated with the Accounts
Map<Id, Contact> accountIdToContactMap = new Map<Id, Contact>();
for (Contact con : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountIds]) {
    accountIdToContactMap.put(con.AccountId, con);
}

// Extract Contact IDs from the Map values
Set<Id> contactIds = new Set<Id>();
for (Contact con : accountIdToContactMap.values()) {
    contactIds.add(con.Id);
}

// Query all Users associated with the Contacts
Map<Id, User> contactIdToUserMap = new Map<Id, User>();
for (User usr : [SELECT Id, ContactId FROM User WHERE ContactId IN :contactIds]) {
    contactIdToUserMap.put(usr.ContactId, usr);
}

        // Loop through each Account record
        for (Account acc : accountsToProcess) {
            // Check if the Account has the 'Distributor' RecordType
            if (acc.RecordType.DeveloperName == 'Distributor') {
                // Get the Contact associated with the Account
                Contact con = accountIdToContactMap.get(acc.Id);
                if (con != null) {
                    // Get the User associated with the Contact
                    User usr = contactIdToUserMap.get(con.Id);
                    if (usr != null && usr.Id == loggedInUserId) {
                        // Create a new AccountShare record to share the account with the logged-in user
                        AccountShare accShare = new AccountShare();
                        accShare.AccountId = acc.Id;  // Share the Account
                        accShare.UserOrGroupId = loggedInUserId;  // Share with the logged-in user
                        accShare.RowCause = Schema.AccountShare.RowCause.Manual; // Manual sharing
                       

                        // Add to the list of shares to insert
                        sharesToInsert.add(accShare);
                    }
                }
            }
        }

        // Insert sharing records if any
        if (!sharesToInsert.isEmpty()) {
            insert sharesToInsert;
        }
    }
}