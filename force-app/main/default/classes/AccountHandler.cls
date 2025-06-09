public class AccountHandler {
    public static void handleNewAccounts(List<Account> newAccounts) {
        Set<Id> userIds = new Set<Id>();
        Map<Id, Date> accountDates = new Map<Id, Date>();

        for (Account acc : newAccounts) {
            if (acc.CreatedById != null) {
                userIds.add(acc.CreatedById);
                accountDates.put(acc.Id, acc.CreatedDate.date());
            }
        }

        // Get user profiles and lifetime field
        Map<Id, User> userMap = new Map<Id, User>(
            [SELECT Id, Profile.Name, New_Unique_Retailer_Added_In_Lifetime__c 
             FROM User 
             WHERE Id IN :userIds]
        );

        Map<Id, User> usersToUpdate = new Map<Id, User>();
        List<ASM_AOP_Target__c> aopToUpdate = new List<ASM_AOP_Target__c>();
        Map<String, ASM_AOP_Target__c> aopCache = new Map<String, ASM_AOP_Target__c>();
        Set<String> lookupKeys = new Set<String>();

        // Build lookup keys: "UserId-Year"
        for (Account acc : newAccounts) {
            if (userMap.containsKey(acc.CreatedById)) {
                User user = userMap.get(acc.CreatedById);
                Date createdDate = acc.CreatedDate.date();
                String key = user.Id + '-' + createdDate.year();
                lookupKeys.add(key);
            }
        }

        // Query existing AOP Target records
        List<ASM_AOP_Target__c> existingAOP = [
            SELECT Id, Sales_Rep__c, Year__c,
                January_Unique_Retailer_Added_in_MTD__c,
                February_Unique_Retailer_Added_in_MTD__c,
                March_Unique_Retailer_Added_in_MTD__c,
                April_Unique_Retailer_Added_in_MTD__c,
                May_Unique_Retailer_Added_in_MTD__c,
                June_Unique_Retailer_Added_in_MTD__c,
                July_Unique_Retailer_Added_in_MTD__c,
                August_Unique_Retailer_Added_in_MTD__c,
                September_Unique_Retailer_Added_in_MTD__c,
                October_Unique_Retailer_Added_in_MTD__c,
                November_Unique_Retailer_Added_in_MTD__c,
                December_Unique_Retailer_Added_in_MTD__c
            FROM ASM_AOP_Target__c
           WHERE Sales_Rep__c IN :userIds AND Year__c IN :getYearsAsString(new Set<Date>(accountDates.values()))
        ];

        for (ASM_AOP_Target__c target : existingAOP) {
            String key = target.Sales_Rep__c + '-' + String.valueOf(target.Year__c);
            aopCache.put(key, target);
        }

        for (Account acc : newAccounts) {
            User creator = userMap.get(acc.CreatedById);
            if (creator == null) continue;

            // Always update lifetime field
            creator.New_Unique_Retailer_Added_In_Lifetime__c = 
                (creator.New_Unique_Retailer_Added_In_Lifetime__c == null ? 1 : creator.New_Unique_Retailer_Added_In_Lifetime__c + 1);
            usersToUpdate.put(creator.Id, creator);

            // Only Sales Rep proceeds with AOP update
            if (creator.Profile.Name != 'Sales Representative') continue;

            Date accDate = acc.CreatedDate.date();
            Integer year = accDate.year();
            Integer month = accDate.month();
            String fieldName = getMonthField(month);
            String key = creator.Id + '-' + year;

            ASM_AOP_Target__c target;
            if (aopCache.containsKey(key)) {
                target = aopCache.get(key);
            } else {
                target = new ASM_AOP_Target__c(
                    Sales_Rep__c = creator.Id
                );
                aopCache.put(key, target);
            }

            // Update the correct month field
            Decimal currentDecimal = (Decimal) target.get(fieldName);
Integer current = currentDecimal == null ? 0 : currentDecimal.intValue();
target.put(fieldName, current + 1);

        }

        if (!usersToUpdate.isEmpty()) {
            update usersToUpdate.values();
        }

        if (!aopCache.isEmpty()) {
            List<ASM_AOP_Target__c> toInsert = new List<ASM_AOP_Target__c>();
            List<ASM_AOP_Target__c> toUpdate = new List<ASM_AOP_Target__c>();

            for (ASM_AOP_Target__c aop : aopCache.values()) {
                if (aop.Id == null) {
                    toInsert.add(aop);
                } else {
                    toUpdate.add(aop);
                }
            }

            if (!toInsert.isEmpty()) insert toInsert;
            if (!toUpdate.isEmpty()) update toUpdate;
        }
    }

    private static String getMonthField(Integer month) {
        switch on month {
            when 1 { return 'January_Unique_Retailer_Added_in_MTD__c'; }
            when 2 { return 'February_Unique_Retailer_Added_in_MTD__c'; }
            when 3 { return 'March_Unique_Retailer_Added_in_MTD__c'; }
            when 4 { return 'April_Unique_Retailer_Added_in_MTD__c'; }
            when 5 { return 'May_Unique_Retailer_Added_in_MTD__c'; }
            when 6 { return 'June_Unique_Retailer_Added_in_MTD__c'; }
            when 7 { return 'July_Unique_Retailer_Added_in_MTD__c'; }
            when 8 { return 'August_Unique_Retailer_Added_in_MTD__c'; }
            when 9 { return 'September_Unique_Retailer_Added_in_MTD__c'; }
            when 10 { return 'October_Unique_Retailer_Added_in_MTD__c'; }
            when 11 { return 'November_Unique_Retailer_Added_in_MTD__c'; }
            when 12 { return 'December_Unique_Retailer_Added_in_MTD__c'; }
            when else { return null; }
        }
    }

private static Set<String> getYearsAsString(Set<Date> dates) {
    Set<String> years = new Set<String>();
    for (Date d : dates) {
        years.add(String.valueOf(d.year()));
    }
    return years;
}
}