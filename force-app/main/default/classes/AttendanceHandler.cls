public class AttendanceHandler {
    
    public static void updateAttendanceCounts(List<Attendance__c> newAttendances) {
        Map<Id, Map<Date, Attendance__c>> uniqueDailyAttendanceMap = new Map<Id, Map<Date, Attendance__c>>();
        
        Set<Id> attendanceIds = new Set<Id>();
Map<Id, Attendance__c> attendanceMapById = new Map<Id, Attendance__c>();

for (Attendance__c att : newAttendances) {
    if (att.User__c == null || att.Absent__c) continue;

    attendanceIds.add(att.Id);
    attendanceMapById.put(att.Id, att);
}

Map<Id, List<Attendance__c>> userDateToExistingAtts = new Map<Id, List<Attendance__c>>();
for (Attendance__c att : attendanceMapById.values()) {
    Date attDate = att.Check_In__c.date();
    List<Attendance__c> existingAtts = [
        SELECT Id, User__c, Check_In__c
        FROM Attendance__c
        WHERE User__c = :att.User__c
        AND Absent__c = false
        AND CALENDAR_YEAR(Check_In__c) = :attDate.year()
        AND CALENDAR_MONTH(Check_In__c) = :attDate.month()
        AND DAY_ONLY(Check_In__c) = :attDate
        AND Id != :att.Id
        LIMIT 1
    ];

    if (!existingAtts.isEmpty()) continue;
            if (!uniqueDailyAttendanceMap.containsKey(att.User__c)) {
                uniqueDailyAttendanceMap.put(att.User__c, new Map<Date, Attendance__c>());
            }

            Map<Date, Attendance__c> dateMap = uniqueDailyAttendanceMap.get(att.User__c);

            if (!dateMap.containsKey(attDate) || att.CreatedDate < dateMap.get(attDate).CreatedDate) {
                dateMap.put(attDate, att);
            }
        }

        if (uniqueDailyAttendanceMap.isEmpty()) return;

        Set<Id> userIds = uniqueDailyAttendanceMap.keySet();

        List<ASM_AOP_Target__c> existingTargets = [
            SELECT Id, Sales_Rep__c, Year__c,
                January_Total_Attendance__c, February_Attendance__c, March_Attendance__c,
                April_Attendance__c, May_Attendance__c, June_Attendance__c,
                July_Attendance__c, August_Attendance__c, September_Attendance__c,
                October_Attendance__c, November_Attendance__c, December_Attendance__c,
                Daily_Average__c
            FROM ASM_AOP_Target__c
            WHERE Sales_Rep__c IN :userIds
        ];

        Map<String, ASM_AOP_Target__c> userYearToTargetMap = new Map<String, ASM_AOP_Target__c>();
        for (ASM_AOP_Target__c target : existingTargets) {
            if (target.Sales_Rep__c != null && target.Year__c != null) {
                String key = target.Sales_Rep__c + '-' + String.valueOf(target.Year__c);
                userYearToTargetMap.put(key, target);
            }
        }

        Map<Id, ASM_AOP_Target__c> updatedTargets = new Map<Id, ASM_AOP_Target__c>();
        List<ASM_AOP_Target__c> newTargetsToInsert = new List<ASM_AOP_Target__c>();

        for (Id userId : uniqueDailyAttendanceMap.keySet()) {
            for (Date attDate : uniqueDailyAttendanceMap.get(userId).keySet()) {
                Attendance__c att = uniqueDailyAttendanceMap.get(userId).get(attDate);
                Integer year = att.CreatedDate.year();
                Integer month = att.CreatedDate.month();
                String key = userId + '-' + String.valueOf(year);

                ASM_AOP_Target__c target;
                Boolean isNew = false;

                if (userYearToTargetMap.containsKey(key)) {
                    target = userYearToTargetMap.get(key);
                } else {
                    target = new ASM_AOP_Target__c(Sales_Rep__c = userId);
                    isNew = true;
                    userYearToTargetMap.put(key, target);
                }

                switch on month {
                    when 1  { target.January_Total_Attendance__c = safeIncrement(target.January_Total_Attendance__c); }
                    when 2  { target.February_Attendance__c      = safeIncrement(target.February_Attendance__c); }
                    when 3  { target.March_Attendance__c         = safeIncrement(target.March_Attendance__c); }
                    when 4  { target.April_Attendance__c         = safeIncrement(target.April_Attendance__c); }
                    when 5  { target.May_Attendance__c           = safeIncrement(target.May_Attendance__c); }
                    when 6  { target.June_Attendance__c          = safeIncrement(target.June_Attendance__c); }
                    when 7  { target.July_Attendance__c          = safeIncrement(target.July_Attendance__c); }
                    when 8  { target.August_Attendance__c        = safeIncrement(target.August_Attendance__c); }
                    when 9  { target.September_Attendance__c     = safeIncrement(target.September_Attendance__c); }
                    when 10 { target.October_Attendance__c       = safeIncrement(target.October_Attendance__c); }
                    when 11 { target.November_Attendance__c      = safeIncrement(target.November_Attendance__c); }
                    when 12 { target.December_Attendance__c      = safeIncrement(target.December_Attendance__c); }
                }

                if (isNew) {
                    newTargetsToInsert.add(target);
                } else {
                    updatedTargets.put(target.Id, target);
                }
            }
        }

        calculateDailyAverage(userYearToTargetMap);

        if (!updatedTargets.isEmpty()) {
            update updatedTargets.values();
        }

        if (!newTargetsToInsert.isEmpty()) {
            insert newTargetsToInsert;
        }
    }

    // Safely increment a Number field
    private static Decimal safeIncrement(Decimal val) {
        return (val == null) ? 1 : val + 1;
    }

    private static void calculateDailyAverage(Map<String, ASM_AOP_Target__c> userYearToTargetMap) {
        Integer currentMonth = System.today().month();
        Integer currentYear = System.today().year();

        Map<Id, Decimal> userVisitCounts = new Map<Id, Decimal>();
        AggregateResult[] visitAggs = [
            SELECT OwnerId ownerId, COUNT(Id) visitCount
            FROM Visit
            WHERE Status = 'Completed'
                AND CALENDAR_MONTH(ActualVisitStartTime) = :currentMonth
                AND CALENDAR_YEAR(ActualVisitStartTime) = :currentYear
            GROUP BY OwnerId
        ];

        for (AggregateResult ar : visitAggs) {
            Id ownerId = (Id) ar.get('ownerId');
            Decimal count = (Decimal) ar.get('visitCount');
            userVisitCounts.put(ownerId, count);
        }

        for (ASM_AOP_Target__c target : userYearToTargetMap.values()) {
            if (target.Year__c != String.valueOf(currentYear)) continue;

            Decimal attendance;
            Decimal visits = userVisitCounts.get(target.Sales_Rep__c);

            switch on currentMonth {
                when 1  { attendance = target.January_Total_Attendance__c; }
                when 2  { attendance = target.February_Attendance__c; }
                when 3  { attendance = target.March_Attendance__c; }
                when 4  { attendance = target.April_Attendance__c; }
                when 5  { attendance = target.May_Attendance__c; }
                when 6  { attendance = target.June_Attendance__c; }
                when 7  { attendance = target.July_Attendance__c; }
                when 8  { attendance = target.August_Attendance__c; }
                when 9  { attendance = target.September_Attendance__c; }
                when 10 { attendance = target.October_Attendance__c; }
                when 11 { attendance = target.November_Attendance__c; }
                when 12 { attendance = target.December_Attendance__c; }
            }

            if (visits != null && attendance != null && attendance > 0) {
                target.Daily_Average__c = visits / attendance;
            }
        }
    }
}