public class VisitHandler {
    
    public static void handleTrigger(List<Visit> newList, Map<Id, Visit> oldMap, Boolean isInsert, Boolean isUpdate) {
        List<Visit> completedVisits = new List<Visit>();

        for (Visit v : newList) {
            if (v.Status == 'Completed' &&
                (isInsert || (isUpdate && oldMap != null && oldMap.get(v.Id).Status != 'Completed'))) {
                completedVisits.add(v);
            }
        }

        if (!completedVisits.isEmpty()) {
            updateVisitMetrics(completedVisits);
        }
    }
 public static void updateVisitMetrics(List<Visit> visits) {
        Set<Id> userIds = new Set<Id>();
        Set<Id> visitIds = new Set<Id>();
        Map<Id, List<Visit>> userToVisits = new Map<Id, List<Visit>>();

        for (Visit v : visits) {
            if (v.cgcloud__Responsible__c != null && v.ActualVisitEndTime != null) {
                userIds.add(v.cgcloud__Responsible__c);
                visitIds.add(v.Id);
                if (!userToVisits.containsKey(v.cgcloud__Responsible__c)) {
                    userToVisits.put(v.cgcloud__Responsible__c, new List<Visit>());
                }
                userToVisits.get(v.cgcloud__Responsible__c).add(v);
            }
        }

        if (userIds.isEmpty()) return;

        Date today = Date.today();
        Integer currentYear = today.year();
        Integer currentMonth = today.month();
        Date startOfWeek = today.toStartOfWeek();
        Date endOfWeek = startOfWeek.addDays(6);
        Date startOfMonth = today.toStartOfMonth();
        Date endOfMonth = startOfMonth.addMonths(1).addDays(-1);

        Map<String, ASM_AOP_Target__c> keyToTarget = new Map<String, ASM_AOP_Target__c>();
        List<ASM_AOP_Target__c> existingTargets = [
            SELECT Id, Sales_Rep__c, Year__c,
                January_MTD_visits__c, February_MTD_Visits__c, March_MTD_Visits__c,
                April_MTD_Visits__c, May_MTD_Visits__c, June_MTD_Visits__c,
                July_MTD_Visits__c, August_MTD_Visits__c, September_MTD_Visits__c,
                October_MTD_visits__c, November_MTD_Visits__c, December_MTD_visits__c,
                January_Total_Attendance__c, February_Attendance__c, March_Attendance__c,
                April_Attendance__c, May_Attendance__c, June_Attendance__c,
                July_Attendance__c, August_Attendance__c, September_Attendance__c,
                October_Attendance__c, November_Attendance__c, December_Attendance__c,
                January_Total_Unique_Visits_MTD__c, February_Total_Unique_Visits_MTD__c,
                March_Total_Unique_Visits_MTD__c, April_Total_Unique_Visits_MTD__c,
                May_Total_Unique_Visits_MTD__c, June_Total_Unique_Visits_MTD__c,
                July_Total_Unique_Visits_MTD__c, August_Total_Unique_Visits_MTD__c,
                September_Total_Unique_Visits_MTD__c, October_Total_Unique_Visits_MTD__c,
                November_Total_Unique_Visits_MTD__c, December_Total_Unique_Visits_MTD__c,
                WTD_Visits__c, Day_visits__c, Daily_Average__c
            FROM ASM_AOP_Target__c
            WHERE Sales_Rep__c IN :userIds AND Year__c = :String.valueOf(currentYear)
        ];

        for (ASM_AOP_Target__c aop : existingTargets) {
            keyToTarget.put(aop.Sales_Rep__c + '_' + currentYear, aop);
        }

        List<ASM_AOP_Target__c> toInsert = new List<ASM_AOP_Target__c>();
        Set<ASM_AOP_Target__c> toUpdate = new Set<ASM_AOP_Target__c>();

        Map<Id, Set<Id>> userToVisitedAccounts = new Map<Id, Set<Id>>();
        List<AggregateResult> priorVisits = [
            SELECT cgcloud__Responsible__c rep, AccountId acct
            FROM Visit
            WHERE ActualVisitEndTime >= :DateTime.newInstance(startOfMonth, Time.newInstance(0, 0, 0, 0))
              AND ActualVisitEndTime <= :DateTime.newInstance(endOfMonth, Time.newInstance(23, 59, 59, 999))
              AND Status = 'Completed'
              AND cgcloud__Responsible__c IN :userIds
              AND AccountId != null
              AND Id NOT IN :visitIds
            GROUP BY cgcloud__Responsible__c, AccountId
        ];

        for (AggregateResult ar : priorVisits) {
            Id rep = (Id) ar.get('rep');
            Id acct = (Id) ar.get('acct');
            if (!userToVisitedAccounts.containsKey(rep)) {
                userToVisitedAccounts.put(rep, new Set<Id>());
            }
            userToVisitedAccounts.get(rep).add(acct);
        }

        for (Id userId : userToVisits.keySet()) {
            String key = userId + '_' + currentYear;
            ASM_AOP_Target__c aop;

            if (keyToTarget.containsKey(key)) {
                aop = keyToTarget.get(key);
            } else {
                aop = new ASM_AOP_Target__c(Sales_Rep__c = userId);
                keyToTarget.put(key, aop);
                toInsert.add(aop);
            }

            Integer mtdCount = 0;
            Integer wtdCount = 0;
            Integer newUniqueCount = 0;
            Integer dayCount = 0;

            if (!userToVisitedAccounts.containsKey(userId)) {
                userToVisitedAccounts.put(userId, new Set<Id>());
            }
            Set<Id> visitedAccounts = userToVisitedAccounts.get(userId).clone();

            for (Visit v : userToVisits.get(userId)) {
                DateTime actualEndTime = v.ActualVisitEndTime;
                if (actualEndTime == null) continue;

                Date completedDate = actualEndTime.date();
                Id acctId = v.AccountId;

                if (completedDate.year() == currentYear && completedDate.month() == currentMonth) {
                    mtdCount++;
                    if (acctId != null && !visitedAccounts.contains(acctId)) {
                        newUniqueCount++;
                        visitedAccounts.add(acctId);
                    }
                }

                if (completedDate >= startOfWeek && completedDate <= endOfWeek) {
                    wtdCount++;
                }

                if (completedDate == today) {
                    dayCount++;
                }
            }

            Decimal monthAttendance = 0;
            Decimal monthVisits = 0;

            switch on currentMonth {
                when 1 {
                    aop.January_MTD_visits__c = nvl(aop.January_MTD_visits__c) + mtdCount;
                    monthAttendance = nvl(aop.January_Total_Attendance__c);
                    monthVisits = aop.January_MTD_visits__c;
                }
                when 2 {
                    aop.February_MTD_Visits__c = nvl(aop.February_MTD_Visits__c) + mtdCount;
                    monthAttendance = nvl(aop.February_Attendance__c);
                    monthVisits = aop.February_MTD_Visits__c;
                }
                when 3 {
                    aop.March_MTD_Visits__c = nvl(aop.March_MTD_Visits__c) + mtdCount;
                    monthAttendance = nvl(aop.March_Attendance__c);
                    monthVisits = aop.March_MTD_Visits__c;
                }
                when 4 {
                    aop.April_MTD_Visits__c = nvl(aop.April_MTD_Visits__c) + mtdCount;
                    monthAttendance = nvl(aop.April_Attendance__c);
                    monthVisits = aop.April_MTD_Visits__c;
                }
                when 5 {
                    aop.May_MTD_Visits__c = nvl(aop.May_MTD_Visits__c) + mtdCount;
                    monthAttendance = nvl(aop.May_Attendance__c);
                    monthVisits = aop.May_MTD_Visits__c;
                }
                when 6 {
                    aop.June_MTD_Visits__c = nvl(aop.June_MTD_Visits__c) + mtdCount;
                    monthAttendance = nvl(aop.June_Attendance__c);
                    monthVisits = aop.June_MTD_Visits__c;
                }
                when 7 {
                    aop.July_MTD_Visits__c = nvl(aop.July_MTD_Visits__c) + mtdCount;
                    monthAttendance = nvl(aop.July_Attendance__c);
                    monthVisits = aop.July_MTD_Visits__c;
                }
                when 8 {
                    aop.August_MTD_Visits__c = nvl(aop.August_MTD_Visits__c) + mtdCount;
                    monthAttendance = nvl(aop.August_Attendance__c);
                    monthVisits = aop.August_MTD_Visits__c;
                }
                when 9 {
                    aop.September_MTD_Visits__c = nvl(aop.September_MTD_Visits__c) + mtdCount;
                    monthAttendance = nvl(aop.September_Attendance__c);
                    monthVisits = aop.September_MTD_Visits__c;
                }
                when 10 {
                    aop.October_MTD_visits__c = nvl(aop.October_MTD_visits__c) + mtdCount;
                    monthAttendance = nvl(aop.October_Attendance__c);
                    monthVisits = aop.October_MTD_visits__c;
                }
                when 11 {
                    aop.November_MTD_Visits__c = nvl(aop.November_MTD_Visits__c) + mtdCount;
                    monthAttendance = nvl(aop.November_Attendance__c);
                    monthVisits = aop.November_MTD_Visits__c;
                }
                when 12 {
                    aop.December_MTD_visits__c = nvl(aop.December_MTD_visits__c) + mtdCount;
                    monthAttendance = nvl(aop.December_Attendance__c);
                    monthVisits = aop.December_MTD_visits__c;
                }
            }

            aop.Daily_Average__c = monthAttendance > 0 ? (monthVisits / monthAttendance).setScale(2) : 0;
            aop.WTD_Visits__c = nvl(aop.WTD_Visits__c) + wtdCount;
            aop.Day_visits__c = nvl(aop.Day_visits__c) + dayCount;

            if (newUniqueCount > 0) {
                switch on currentMonth {
                    when 1  { aop.January_Total_Unique_Visits_MTD__c = nvl(aop.January_Total_Unique_Visits_MTD__c) + newUniqueCount; }
                    when 2  { aop.February_Total_Unique_Visits_MTD__c = nvl(aop.February_Total_Unique_Visits_MTD__c) + newUniqueCount; }
                    when 3  { aop.March_Total_Unique_Visits_MTD__c = nvl(aop.March_Total_Unique_Visits_MTD__c) + newUniqueCount; }
                    when 4  { aop.April_Total_Unique_Visits_MTD__c = nvl(aop.April_Total_Unique_Visits_MTD__c) + newUniqueCount; }
                    when 5  { aop.May_Total_Unique_Visits_MTD__c = nvl(aop.May_Total_Unique_Visits_MTD__c) + newUniqueCount; }
                    when 6  { aop.June_Total_Unique_Visits_MTD__c = nvl(aop.June_Total_Unique_Visits_MTD__c) + newUniqueCount; }
                    when 7  { aop.July_Total_Unique_Visits_MTD__c = nvl(aop.July_Total_Unique_Visits_MTD__c) + newUniqueCount; }
                    when 8  { aop.August_Total_Unique_Visits_MTD__c = nvl(aop.August_Total_Unique_Visits_MTD__c) + newUniqueCount; }
                    when 9  { aop.September_Total_Unique_Visits_MTD__c = nvl(aop.September_Total_Unique_Visits_MTD__c) + newUniqueCount; }
                    when 10 { aop.October_Total_Unique_Visits_MTD__c = nvl(aop.October_Total_Unique_Visits_MTD__c) + newUniqueCount; }
                    when 11 { aop.November_Total_Unique_Visits_MTD__c = nvl(aop.November_Total_Unique_Visits_MTD__c) + newUniqueCount; }
                    when 12 { aop.December_Total_Unique_Visits_MTD__c = nvl(aop.December_Total_Unique_Visits_MTD__c) + newUniqueCount; }
                }
            }

            toUpdate.add(aop);
        }

        if (!toInsert.isEmpty()) {
            insert toInsert;
            toUpdate.addAll(toInsert);
        }

        if (!toUpdate.isEmpty()) {
            update new List<ASM_AOP_Target__c>(toUpdate);
        }
    

        // --- LIFETIME UNIQUE VISIT TRACKING ---

    // Collect all visits IDs in the current batch to exclude from lifetime count query
    Set<Id> currentVisitIds = new Set<Id>();
    for (Visit v : visits) {
        currentVisitIds.add(v.Id);
    }

    List<AggregateResult> lifetimeVisitResults = [
        SELECT cgcloud__Responsible__c rep, AccountId acct
        FROM Visit
        WHERE Status = 'Completed'
          AND AccountId != null
          AND cgcloud__Responsible__c IN :userIds
          AND Id NOT IN :currentVisitIds
        GROUP BY cgcloud__Responsible__c, AccountId
    ];

    // Declare map to hold reps and accounts visited historically
    Map<Id, Set<Id>> lifetimeVisitedAccounts = new Map<Id, Set<Id>>();

    for (AggregateResult ar : lifetimeVisitResults) {
        Id repId = (Id) ar.get('rep');
        Id acctId = (Id) ar.get('acct');
        if (!lifetimeVisitedAccounts.containsKey(repId)) {
            lifetimeVisitedAccounts.put(repId, new Set<Id>());
        }
        lifetimeVisitedAccounts.get(repId).add(acctId);
    }

    Map<Id, Set<Id>> newLifetimeAccounts = new Map<Id, Set<Id>>();

    for (Visit v : visits) {
        Id userId = v.cgcloud__Responsible__c;
        Id acctId = v.AccountId;
        if (userId == null || acctId == null || v.ActualVisitEndTime == null) continue;

        if (!lifetimeVisitedAccounts.containsKey(userId)) {
            lifetimeVisitedAccounts.put(userId, new Set<Id>());
        }

        if (!lifetimeVisitedAccounts.get(userId).contains(acctId)) {
            if (!newLifetimeAccounts.containsKey(userId)) {
                newLifetimeAccounts.put(userId, new Set<Id>());
            }
            newLifetimeAccounts.get(userId).add(acctId);
            lifetimeVisitedAccounts.get(userId).add(acctId);
        }
    }

    List<User> usersToUpdate = new List<User>();

    for (Id userId : newLifetimeAccounts.keySet()) {
        Integer newCount = newLifetimeAccounts.get(userId).size();

        if (newCount > 0) {
            User u = [SELECT Id, Total_Unique_Visits__c FROM User WHERE Id = :userId LIMIT 1];
            Integer existingCount = u.Total_Unique_Visits__c == null ? 0 : u.Total_Unique_Visits__c.intValue();


            usersToUpdate.add(new User(
                Id = userId,
                Total_Unique_Visits__c = existingCount + newCount
            ));
        }
    }

    if (!usersToUpdate.isEmpty()) {
        update usersToUpdate;
    }
}

private static Decimal nvl(Decimal val) {
    return val == null ? 0 : val;
}

private static Integer nvl(Integer val) {
    return val == null ? 0 : val;
}
}