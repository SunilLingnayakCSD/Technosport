public class LeadPincodeSharingHandler {

    // Method for non-sharing functionality (before insert)
    public static void handleLeadBeforeInsert(Lead__c newLead) {
        // Step 1: Extract the pincode from the lead
        String leadPincode = newLead.Address__PostalCode__s;

        // Debug: Log the pincode from the lead
        System.debug('Pincode extracted from lead: ' + leadPincode);

        // Step 2: Query distributor accounts with matching shipping postal codes
        List<Account> distributorAccounts = [SELECT Id, ShippingPostalCode, RecordTypeId 
                                              FROM Account 
                                              WHERE RecordType.Name = 'Distributor'
                                              AND ShippingPostalCode != NULL
                                              AND ShippingPostalCode = :leadPincode];
        System.debug('distributorAccounts--->'+distributorAccounts);

        // Step 2.1: If no distributor accounts are found, exit early
        if (distributorAccounts.isEmpty()) {
            System.debug('No distributors found for the given pincode: ' + leadPincode);
            return;
        }

        Map<Id, Integer> distributorLeadCountMap = new Map<Id, Integer>();
        for(Account acc: distributorAccounts){
            distributorLeadCountMap.put(acc.Id, 0);
        }

        Id assigneeId;
        System.debug('distributorAccounts size-->'+distributorAccounts.size());

        if(!distributorAccounts.isEmpty()){
            if(distributorAccounts.size() > 1){
                List<Lead__c> existingLeads = [SELECT Id, Assigned_Distributor__c FROM Lead__c WHERE Assigned_Distributor__c IN :distributorAccounts];
                System.debug('Existing leads-->' + existingLeads);
                
                for(Lead__c ll : existingLeads){
                    Integer currentCount = distributorLeadCountMap.get(ll.Assigned_Distributor__c);
                    distributorLeadCountMap.put(ll.Assigned_Distributor__c, currentCount + 1);
                }

                Integer maxRemLoad = 2147483647;
                for (Id uId : distributorLeadCountMap.keySet()){
                    System.debug('distributorLeadCountMap--->'+distributorLeadCountMap.get(uId));
                    if (distributorLeadCountMap.get(uId) < maxRemLoad){
                        assigneeId = uId;
                        maxRemLoad = distributorLeadCountMap.get(uId);
                        System.debug('assigneeId-->'+assigneeId);
                    }
                }
                newLead.Assigned_Distributor__c = assigneeId;
                System.debug('Assigned Distributor to the new lead: ' + assigneeId);
            } else {
                assigneeId = distributorAccounts[0].Id;
                newLead.Assigned_Distributor__c = distributorAccounts[0].Id;
                System.debug('Assigned Distributor to the new lead: ' + assigneeId);
            }
        }
    }

    // Method for sharing functionality (after insert)
    public static void handleLeadAfterInsert(Lead__c newLead) {
        List<Lead__share> leadShareRecords = new List<Lead__share>();

        // Step 1: Get the assigned distributor for the lead
        Id assigneeId = newLead.Assigned_Distributor__c;

        // Step 2: Assign the lead to the selected distributor if assigneeId is not null
        if (assigneeId != null) {
            // Query all active users for the selected distributor
            List<User> distributorUsers = [SELECT Id FROM User WHERE AccountId = :assigneeId AND IsActive = TRUE];
            System.debug('distributorUsers--->' + distributorUsers);

            // Create sharing records for each active user associated with the selected distributor
            for (User u : distributorUsers) {
                Lead__share leadShare = new Lead__share();
                leadShare.ParentId = newLead.Id;  // The Lead__c Id to share
                leadShare.UserOrGroupId = u.Id;  // User Id to share the Lead__c with
                leadShare.AccessLevel = 'Edit';  // Access Level for sharing (Read or Edit)

                // Add the share record to the list
                leadShareRecords.add(leadShare);
            }

            // Step 3: Insert sharing records
            if (!leadShareRecords.isEmpty()) {
                try {
                    insert leadShareRecords; // Insert sharing records
                    System.debug('Successfully inserted sharing records for Lead ID: ' + newLead.Id);
                } catch (DmlException e) {
                    System.debug('Error creating sharing records: ' + e.getMessage());
                }
            } else {
                System.debug('No sharing records to insert.');
            }
        } else {
            System.debug('No distributor found to assign the lead.');
        }
    }
}