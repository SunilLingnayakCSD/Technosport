public class AccountTriggerHandler {

    public static void handleAccountSharing(List<Account> accountsToProcess) {
        List<AccountShare> sharesToInsert = new List<AccountShare>();

        Id loggedInUserId = UserInfo.getUserId();

        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accountsToProcess) {
            if (acc.RecordType.DeveloperName == 'Distributor') {
                accountIds.add(acc.Id);
            }
        }

Map<Id, Contact> accountIdToContactMap = new Map<Id, Contact>();
for (Contact con : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountIds]) {
    accountIdToContactMap.put(con.AccountId, con);
}

Set<Id> contactIds = new Set<Id>();
for (Contact con : accountIdToContactMap.values()) {
    contactIds.add(con.Id);
}

Map<Id, User> contactIdToUserMap = new Map<Id, User>();
for (User usr : [SELECT Id, ContactId FROM User WHERE ContactId IN :contactIds]) {
    contactIdToUserMap.put(usr.ContactId, usr);
}

        for (Account acc : accountsToProcess) {
            
            if (acc.RecordType.DeveloperName == 'Distributor') {
                
                Contact con = accountIdToContactMap.get(acc.Id);
                if (con != null) {
                    
                    User usr = contactIdToUserMap.get(con.Id);
                    if (usr != null && usr.Id == loggedInUserId) {
                       
                        AccountShare accShare = new AccountShare();
                        accShare.AccountId = acc.Id;  
                        accShare.UserOrGroupId = loggedInUserId;  
                        accShare.RowCause = Schema.AccountShare.RowCause.Manual; 
                     	
                       
                        sharesToInsert.add(accShare);
                    }
                }
            }
        }


        if (!sharesToInsert.isEmpty()) {
            insert sharesToInsert;
        }
    }
    
   public static void shareAccountWithDistributor(List<Account> Accounts) {
    
    Set<Id> distributorAccountIds = new Set<Id>();
    for (Account newAccount : Accounts) {
        if (newAccount.RecordType.DeveloperName == 'Customer' && newAccount.Distributor__c != null) {
            distributorAccountIds.add(newAccount.Distributor__c);
        }
    }
    Map<Id, Account> distributorAccountMap = new Map<Id, Account>([
        SELECT Id, Name 
        FROM Account 
        WHERE Id IN :distributorAccountIds
    ]);
    Map<Id, List<User>> distributorUsersMap = new Map<Id, List<User>>();
    for (User user : [
        SELECT Id, Contact.AccountId 
        FROM User 
        WHERE Contact.AccountId IN :distributorAccountIds
        AND Profile.Name = 'Community Distributor Access'
    ]) {
        if (!distributorUsersMap.containsKey(user.Contact.AccountId)) {
            distributorUsersMap.put(user.Contact.AccountId, new List<User>());
        }
        distributorUsersMap.get(user.Contact.AccountId).add(user);
    }
    List<AccountShare> sharesToInsert = new List<AccountShare>();
    for (Account newAccount : Accounts) {
        if (newAccount.RecordType.DeveloperName == 'Customer' && newAccount.Distributor__c != null) {
            Account distributorAccount = distributorAccountMap.get(newAccount.Distributor__c);

            if (distributorAccount != null && distributorUsersMap.containsKey(distributorAccount.Id)) {
                List<User> distributorUsers = distributorUsersMap.get(distributorAccount.Id);

                for (User distributorUser : distributorUsers) {
                    AccountShare accShare = new AccountShare();
                    accShare.AccountId = newAccount.Id;  
                    accShare.UserOrGroupId = distributorUser.Id; 
                    accShare.RowCause = Schema.AccountShare.RowCause.Manual;
                    sharesToInsert.add(accShare);
                }
            }
        }
    }
    if (!sharesToInsert.isEmpty()) {
        try {
            insert sharesToInsert;
            System.debug('Account shared with distributor users successfully.');
        } catch (DmlException e) {
            System.debug('Error inserting AccountShare records: ' + e.getMessage());
        }
    }
}

}