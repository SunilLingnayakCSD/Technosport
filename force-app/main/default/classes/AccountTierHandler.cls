public class AccountTierHandler {
       public static void handleRetailerPurchaseChanges(
        List<Retailer_Purchase__c> newList,
        Map<Id, Retailer_Purchase__c> oldMap
    ) {
        Map<Id, String> purchaseIdToQuarter = new Map<Id, String>();
        List<Retailer_Purchase__c> relevantRecords = new List<Retailer_Purchase__c>();

        /* ---------- detect which quarter’s pick‑list changed ---------- */
        for (Retailer_Purchase__c rp : newList) {
            String changedQuarter = null;

            if (oldMap == null) {
                /* INSERT context */
                if      (rp.Q1_Tier__c != null) changedQuarter = 'Q1';
                else if (rp.Q2_Tier__c != null) changedQuarter = 'Q2';
                else if (rp.Q3_Tier__c != null) changedQuarter = 'Q3';
                else if (rp.Q4_Tier__c != null) changedQuarter = 'Q4';
            } else {
                /* UPDATE context */
                Retailer_Purchase__c oldRp = oldMap.get(rp.Id);
                if      (rp.Q1_Tier__c != oldRp.Q1_Tier__c) changedQuarter = 'Q1';
                else if (rp.Q2_Tier__c != oldRp.Q2_Tier__c) changedQuarter = 'Q2';
                else if (rp.Q3_Tier__c != oldRp.Q3_Tier__c) changedQuarter = 'Q3';
                else if (rp.Q4_Tier__c != oldRp.Q4_Tier__c) changedQuarter = 'Q4';
            }

            if (changedQuarter != null) {
                purchaseIdToQuarter.put(rp.Id, changedQuarter);
                relevantRecords.add(rp);
                System.debug(LoggingLevel.INFO,
                    '✓ Detected change in ' + changedQuarter + ' for RP ' + rp.Id);
            }
        }

        if (!relevantRecords.isEmpty()) {
            updateAccountTiers(relevantRecords, purchaseIdToQuarter);
        }
    }

    /* ===============================================================
     *  CORE WORK — look up Tier__c and update Accounts
     * =============================================================== */
    private static void updateAccountTiers(
        List<Retailer_Purchase__c> purchaseList,
        Map<Id, String> purchaseIdToQuarter
    ) {
        /* ---- 1) Collect all tier names (trimmed) we need to resolve ---- */
        Set<String> tierNamesNeeded = new Set<String>();

        for (Retailer_Purchase__c rp : purchaseList) {
            String q = purchaseIdToQuarter.get(rp.Id);
            if (q == null) continue;

            String rawName;
            if      (q == 'Q1') rawName = rp.Q1_Tier__c;
            else if (q == 'Q2') rawName = rp.Q2_Tier__c;
            else if (q == 'Q3') rawName = rp.Q3_Tier__c;
            else                rawName = rp.Q4_Tier__c;

            if (!String.isBlank(rawName)) {
                tierNamesNeeded.add(rawName.trim());
            }
        }

        /* ---- 2) Query Tier__c once, keyed by Name (trimmed) ---- */
        Map<String, Tier__c> tierByName = new Map<String, Tier__c>();
        if (!tierNamesNeeded.isEmpty()) {
            for (Tier__c t : [
                SELECT Id, Name
                FROM Tier__c
                WHERE Name IN :tierNamesNeeded
            ]) {
                tierByName.put(t.Name.trim(), t);
            }
        }

        /* ---- 3) Build ONE update per Account ---- */
        Map<Id, Account> accUpdates = new Map<Id, Account>();

        for (Retailer_Purchase__c rp : purchaseList) {
            String q = purchaseIdToQuarter.get(rp.Id);
            if (q == null || rp.Retailer__c == null) continue;

            /* pick tier name for that quarter, trim it */
            String tierName;
            if      (q == 'Q1') tierName = rp.Q1_Tier__c;
            else if (q == 'Q2') tierName = rp.Q2_Tier__c;
            else if (q == 'Q3') tierName = rp.Q3_Tier__c;
            else                tierName = rp.Q4_Tier__c;

            if (String.isBlank(tierName)) continue;

            tierName = tierName.trim();
            Tier__c tierRec = tierByName.get(tierName);

            if (tierRec == null) {
                System.debug(LoggingLevel.WARN,
                    '⚠ No Tier__c record found with Name "' + tierName + '"');
                continue;
            }

            /* last one processed for the same Account wins */
            accUpdates.put(
                rp.Retailer__c,
                new Account(
                    Id                       = rp.Retailer__c,
                    Retailer_Tier__c         = tierRec.Id,
                    Current_Benefit_Year__c  = rp.Year__c,
                    Current_Benefit_Quater__c= q
                )
            );
        }

        /* ---- 4) DML once, no duplicate Ids ---- */
        if (!accUpdates.isEmpty()) {
            update accUpdates.values();
            System.debug(LoggingLevel.INFO,
                '✓ Updated ' + accUpdates.size() + ' Account(s) with new tiers');
        }
    }
}