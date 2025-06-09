public with sharing class VisitTargetUpdater {
    public static void updatePlannedVisitTargets(List<Visit> visits) {
        if (visits == null || visits.isEmpty()) return;

        Set<Id> accountIds = new Set<Id>();
        Set<String> years = new Set<String>();
        Map<Id, Date> visitCreatedMap = new Map<Id, Date>();

        for (Visit visit : visits) {
            accountIds.add(visit.AccountId);
            String year = String.valueOf(visit.CreatedDate.year());
            years.add(year);
            visitCreatedMap.put(visit.Id, visit.CreatedDate.date());
        }

        // Fetch AOP records
        List<Retailer_AOP_Target__c> aopList = [
            SELECT Id, Account__c, Year__c,
                Q1_Achieved_Target__c, Q2_Achieved_Target__c, Q3_Achieved_Target__c, Q4_Achieved_Target__c,
                Year_Achieved_Target__c, Quarter_Actual_Target__c,
                January_Achieved_Target__c, February_Achieved_Target__c, March_Achieved_Target__c,
                April_Achieved_Target__c, May_Achieved_Target__c, June_Achieved_Target__c,
                July_Achieved_Target__c, August_Achieved_Target__c, September_Achieved_Target__c,
                October_Achieved_Target__c, November_Achieved_Target__c, December_Achieved_Target__c
            FROM Retailer_AOP_Target__c
            WHERE Account__c IN :accountIds AND Year__c IN :years
        ];

        Map<String, Retailer_AOP_Target__c> aopMap = new Map<String, Retailer_AOP_Target__c>();
        for (Retailer_AOP_Target__c aop : aopList) {
            String key = aop.Account__c + '-' + String.valueOf(aop.Year__c);
            aopMap.put(key, aop);
        }

        List<Visit> updates = new List<Visit>();

        for (Visit visit : visits) {
            Date created = visitCreatedMap.get(visit.Id);
            Integer year = created.year();
            Integer month = created.month();
            Integer quarter = ((month - 1) / 3) + 1;

            String key = visit.AccountId + '-' + String.valueOf(year);
            Retailer_AOP_Target__c aop = aopMap.get(key);
            if (aop == null) continue;

            Integer mtd = 0;
            switch on month {
                when 1 { mtd = aop.January_Achieved_Target__c != null ? aop.January_Achieved_Target__c.intValue() : 0; }
                when 2 { mtd = aop.February_Achieved_Target__c != null ? aop.February_Achieved_Target__c.intValue() : 0; }
                when 3 { mtd = aop.March_Achieved_Target__c != null ? aop.March_Achieved_Target__c.intValue() : 0; }
                when 4 { mtd = aop.April_Achieved_Target__c != null ? aop.April_Achieved_Target__c.intValue() : 0; }
                when 5 { mtd = aop.May_Achieved_Target__c != null ? aop.May_Achieved_Target__c.intValue() : 0; }
                when 6 { mtd = aop.June_Achieved_Target__c != null ? aop.June_Achieved_Target__c.intValue() : 0; }
                when 7 { mtd = aop.July_Achieved_Target__c != null ? aop.July_Achieved_Target__c.intValue() : 0; }
                when 8 { mtd = aop.August_Achieved_Target__c != null ? aop.August_Achieved_Target__c.intValue() : 0; }
                when 9 { mtd = aop.September_Achieved_Target__c != null ? aop.September_Achieved_Target__c.intValue() : 0; }
                when 10 { mtd = aop.October_Achieved_Target__c != null ? aop.October_Achieved_Target__c.intValue() : 0; }
                when 11 { mtd = aop.November_Achieved_Target__c != null ? aop.November_Achieved_Target__c.intValue() : 0; }
                when 12 { mtd = aop.December_Achieved_Target__c != null ? aop.December_Achieved_Target__c.intValue() : 0; }
            }

            Integer qtd = 0;
            switch on quarter {
                when 1 { qtd = aop.Q1_Achieved_Target__c != null ? aop.Q1_Achieved_Target__c.intValue() : 0; }
                when 2 { qtd = aop.Q2_Achieved_Target__c != null ? aop.Q2_Achieved_Target__c.intValue() : 0; }
                when 3 { qtd = aop.Q3_Achieved_Target__c != null ? aop.Q3_Achieved_Target__c.intValue() : 0; }
                when 4 { qtd = aop.Q4_Achieved_Target__c != null ? aop.Q4_Achieved_Target__c.intValue() : 0; }
            }

            updates.add(new Visit(
                Id = visit.Id,
                Retailer_Business_MTD__c = mtd,
                Retailer_Business_QTD__c = qtd,
                Retailer_Business_YTD__c = aop.Year_Achieved_Target__c != null ? aop.Year_Achieved_Target__c : 0,
                Retailer_Quarterly_Target__c = aop.Quarter_Actual_Target__c != null ? aop.Quarter_Actual_Target__c : 0
            ));
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }
}