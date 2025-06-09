public with sharing class LeadPincodeSharingHandler {

    /* -------------------------------------------------
     * BEFORE INSERT  — choose distributor for each lead
     * ------------------------------------------------- */
    public static void prepareDistributorAssignment(List<Lead__c> newLeads) {

        /* 1. Distinct pincodes in incoming leads */
        Set<String> pincodes = new Set<String>();
        for (Lead__c l : newLeads)
            if (String.isNotBlank(l.Address__PostalCode__s))
                pincodes.add(l.Address__PostalCode__s);
        if (pincodes.isEmpty()) return;

        /* 2. All distributors across those pincodes */
        List<Account> distributorList = [
            SELECT Id, ShippingPostalCode
            FROM Account
            WHERE RecordType.Name = 'Distributor'
            AND ShippingPostalCode IN :pincodes
        ];

        /* 3. Map<pincode, List<Distributor>> */
        Map<String, List<Account>> pinToDists = new Map<String, List<Account>>();
        Set<Id> distributorIds = new Set<Id>();
        for (Account d : distributorList) {
            List<Account> lst = pinToDists.get(d.ShippingPostalCode);
            if (lst == null) {
                lst = new List<Account>();
                pinToDists.put(d.ShippingPostalCode, lst);
            }
            lst.add(d);
            distributorIds.add(d.Id);
        }
        if (pinToDists.isEmpty()) return;

        /* 4. Existing‐lead counts per distributor */
        Map<Id, Integer> distLeadCount = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Assigned_Distributor__c did, COUNT(Id) cnt
            FROM Lead__c
            WHERE Assigned_Distributor__c IN :distributorIds
            GROUP BY Assigned_Distributor__c
        ]) {
            distLeadCount.put(
                (Id) ar.get('did'),
                (Integer) ar.get('cnt')
            );
        }

        /* 5. Assign least‑busy distributor per pincode */
        for (Lead__c l : newLeads) {
            if (String.isBlank(l.Address__PostalCode__s)) continue;

            List<Account> choices = pinToDists.get(l.Address__PostalCode__s);
            if (choices == null) continue;

            Id best;
            Integer min = 2147483647;   // INT max

            for (Account d : choices) {
                Integer c = distLeadCount.containsKey(d.Id) ? distLeadCount.get(d.Id) : 0;
                if (c < min) {
                    min = c;
                    best = d.Id;
                }
            }
            if (best != null) {
                l.Assigned_Distributor__c = best;
                distLeadCount.put(best, min + 1);   // increment live counter
            }
        }
    }

    /* -------------------------------------------------
     * AFTER INSERT — owner assignment to Sales Reps
     * ------------------------------------------------- */
    public static void assignOwners(List<Lead__c> insertedLeads) {

        /* 1. Distinct pincodes */
        Set<String> pincodes = new Set<String>();
        for (Lead__c l : insertedLeads)
            if (String.isNotBlank(l.Address__PostalCode__s))
                pincodes.add(l.Address__PostalCode__s);
        if (pincodes.isEmpty()) return;

        /* 2. Sales reps in those pincodes */
        List<User> repList = [
            SELECT Id, PostalCode
            FROM User
            WHERE IsActive = true
            AND Profile.Name = 'Sales Representative'
            AND PostalCode IN :pincodes
        ];

        Map<String, List<User>> pinToReps = new Map<String, List<User>>();
        Set<Id> repIds = new Set<Id>();
        for (User u : repList) {
            List<User> lst = pinToReps.get(u.PostalCode);
            if (lst == null) {
                lst = new List<User>();
                pinToReps.put(u.PostalCode, lst);
            }
            lst.add(u);
            repIds.add(u.Id);
        }
        if (pinToReps.isEmpty()) return;

        /* 3. Current workload per rep */
        Map<Id, Integer> repLoad = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT OwnerId oid, COUNT(Id) cnt
            FROM Lead__c
            WHERE OwnerId IN :repIds
            AND Lead_Status__c NOT IN ('Converted', 'Not Converted')
            GROUP BY OwnerId
        ]) {
            repLoad.put(
                (Id) ar.get('oid'),
                (Integer) ar.get('cnt')
            );
        }

        /* 4. Pick least‑busy rep for each lead */
        List<Lead__c> updates = new List<Lead__c>();

        for (Lead__c l : insertedLeads) {
            if (String.isBlank(l.Address__PostalCode__s)) continue;

            List<User> choices = pinToReps.get(l.Address__PostalCode__s);
            if (choices == null) continue;

            User pick;
            Integer min = 2147483647;

            for (User u : choices) {
                Integer c = repLoad.containsKey(u.Id) ? repLoad.get(u.Id) : 0;
                if (c < min) { min = c; pick = u; }
            }
            if (pick != null) {
                updates.add(new Lead__c(
                    Id = l.Id,
                    OwnerId = pick.Id,
                    Lead_assigned_to_ASM__c = true
                ));
                repLoad.put(pick.Id, min + 1);
            }
        }
        if (!updates.isEmpty()) update updates;
    }

    /* -------------------------------------------------
     * AFTER INSERT — share with distributor users
     * ------------------------------------------------- */
    public static void shareWithDistributors(List<Lead__c> insertedLeads) {

        /* 1. Distinct distributor Ids */
        Set<Id> distIds = new Set<Id>();
        for (Lead__c l : insertedLeads)
            if (l.Assigned_Distributor__c != null)
                distIds.add(l.Assigned_Distributor__c);
        if (distIds.isEmpty()) return;

        /* 2. Users under those distributors */
        List<User> userList = [
            SELECT Id, AccountId
            FROM User
            WHERE IsActive = true
            AND AccountId IN :distIds
        ];

        Map<Id, List<User>> distToUsers = new Map<Id, List<User>>();
        for (User u : userList) {
            List<User> lst = distToUsers.get(u.AccountId);
            if (lst == null) {
                lst = new List<User>();
                distToUsers.put(u.AccountId, lst);
            }
            lst.add(u);
        }

        /* 3. Build share records */
        List<Lead__share> shares = new List<Lead__share>();

        for (Lead__c l : insertedLeads) {
            if (l.Assigned_Distributor__c == null) continue;

            List<User> uList = distToUsers.get(l.Assigned_Distributor__c);
            if (uList == null) continue;

            for (User u : uList) {
                shares.add(new Lead__share(
                    ParentId      = l.Id,
                    UserOrGroupId = u.Id,
                    AccessLevel   = 'Edit',
                    RowCause      = Schema.Lead__share.RowCause.Manual
                ));
            }
        }
        if (!shares.isEmpty()) insert shares;
    }
}