public class TierBenefitHandler {

    public static void processTierChange(Map<Id, Account> oldMap, Map<Id, Account> newMap) {
        Set<Id> accountIdsToProcess = new Set<Id>();

       for (Id accId : newMap.keySet()) {
    Account oldAcc = oldMap.get(accId);
    Account newAcc = newMap.get(accId);

    Boolean tierChanged    = oldAcc.Retailer_Tier__c          != newAcc.Retailer_Tier__c;
    Boolean yearChanged    = oldAcc.Current_Benefit_Year__c   != newAcc.Current_Benefit_Year__c;
    Boolean quarterChanged = oldAcc.Current_Benefit_Quater__c != newAcc.Current_Benefit_Quater__c;

    if (tierChanged || yearChanged || quarterChanged) {
        accountIdsToProcess.add(accId);
    }
}


        if (accountIdsToProcess.isEmpty()) return;

        // Fetch accounts and their current tier/year/quarter
        Map<Id, Account> accounts = new Map<Id, Account>([
            SELECT Id, Retailer_Tier__c, Current_Benefit_Year__c, Current_Benefit_Quater__c 
            FROM Account
            WHERE Id IN :accountIdsToProcess AND Retailer_Tier__c != NULL
        ]);

        // Map Tier ➜ Benefits
        Set<Id> tierIds = new Set<Id>();
        for (Account acc : accounts.values()) tierIds.add(acc.Retailer_Tier__c);

        Map<Id, List<Benefit__c>> tierToBenefits = new Map<Id, List<Benefit__c>>();
        for (Tier_Benefit__c tb : [
            SELECT Tier__c, Benefit__r.Id, Benefit__r.Type__c
            FROM Tier_Benefit__c
            WHERE Tier__c IN :tierIds
        ]) {
            if (!tierToBenefits.containsKey(tb.Tier__c))
                tierToBenefits.put(tb.Tier__c, new List<Benefit__c>());
            tierToBenefits.get(tb.Tier__c).add(tb.Benefit__r);
        }

        // Existing Retailer Benefits ➜ prevent duplicates
        Set<String> yearlyKeys = new Set<String>();
        Set<String> quarterKeys = new Set<String>();
        Set<String> oneTimeKeys = new Set<String>();

        for (Retailer_Benefit__c rb : [
            SELECT Account__c, Benefit__c, Type__c, Benefit_Year__c
            FROM Retailer_Benefit__c
            WHERE Account__c IN :accountIdsToProcess
        ]) {
            if (rb.Benefit__c == null) continue;

            if (rb.Type__c == 'Yearly') {
                yearlyKeys.add(rb.Account__c + '|' + rb.Benefit_Year__c + '|' + rb.Benefit__c);
            } else if (rb.Type__c == 'One Time') {
                oneTimeKeys.add(rb.Account__c + '|' + rb.Benefit__c);
            } else { // Quarterly Q1–Q4
                quarterKeys.add(rb.Account__c + '|' + rb.Benefit_Year__c + '|' + rb.Type__c + '|' + rb.Benefit__c);
            }
        }

        // Create missing benefit records
        List<Retailer_Benefit__c> toInsert = new List<Retailer_Benefit__c>();

        for (Account acc : accounts.values()) {
            List<Benefit__c> benefits = tierToBenefits.get(acc.Retailer_Tier__c);
            if (benefits == null) continue;

            String year = acc.Current_Benefit_Year__c;
            String quarter = acc.Current_Benefit_Quater__c ;
            
             if (quarter == null) {
                Integer month = System.today().month(); // [ADDED]
                if (month >= 1 && month <= 3) {
                    quarter = 'Q1';
                } else if (month >= 4 && month <= 6) {
                    quarter = 'Q2';
                } else if (month >= 7 && month <= 9) {
                    quarter = 'Q3';
                } else {
                    quarter = 'Q4';
                }
            }

            for (Benefit__c ben : benefits) {
                if (ben.Type__c == 'Yearly') {
                    String key = acc.Id + '|' + year + '|' + ben.Id;
                    if (!yearlyKeys.contains(key)) {
                        toInsert.add(new Retailer_Benefit__c(
                            Account__c      = acc.Id,
                            Benefit__c      = ben.Id,
                            Type__c         = 'Yearly',
                            Status__c       = 'No',
                            Benefit_Year__c = year
                        ));
                    }
                }

                if (ben.Type__c == 'Quarterly' && quarter != null) {
                    String key = acc.Id + '|' + year + '|' + quarter + '|' + ben.Id;
                    if (!quarterKeys.contains(key)) {
                        toInsert.add(new Retailer_Benefit__c(
                            Account__c      = acc.Id,
                            Benefit__c      = ben.Id,
                            Type__c         = quarter,
                            Status__c       = 'No',
                            Benefit_Year__c = year
                        ));
                    }
                }

                if (ben.Type__c == 'One Time') {
                    String key = acc.Id + '|' + ben.Id;
                    if (!oneTimeKeys.contains(key)) {
                        toInsert.add(new Retailer_Benefit__c(
                            Account__c = acc.Id,
                            Benefit__c = ben.Id,
                            Type__c    = 'One Time',
                            Status__c  = 'No'
                        ));
                    }
                }
            }
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
        }
    }
}