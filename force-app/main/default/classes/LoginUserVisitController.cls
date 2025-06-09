public class LoginUserVisitController {
    @AuraEnabled(cacheable=true)
    public static List<Visit> getVisits(String viewType, Date startDate, Date endDate) {
        List<Visit> visits = new List<Visit>();

        Id currentUserId = UserInfo.getUserId();

        if (viewType == 'daily') {
            DateTime startOfDay = System.today(); // today at 00:00
            DateTime endOfDay = startOfDay.addDays(1); // tomorrow at 00:00

            visits = [
                SELECT Id, Name, PlannedVisitStartTime, Account.Name
                FROM Visit
                WHERE cgcloud__Responsible__c = :currentUserId
                AND Status = 'Planned' 
                AND PlannedVisitStartTime >= :startOfDay
                AND PlannedVisitStartTime < :endOfDay
                ORDER BY PlannedVisitStartTime ASC
            ];
        } else if (viewType == 'weekly' && startDate != null && endDate != null) {
            DateTime startDateTime = DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
            DateTime endDateTime = DateTime.newInstance(endDate.addDays(1), Time.newInstance(0, 0, 0, 0));

            visits = [
                SELECT Id, Name, PlannedVisitStartTime, Account.Name
                FROM Visit
                WHERE cgcloud__Responsible__c = :currentUserId
                AND Status = 'Planned' 
                AND PlannedVisitStartTime >= :startDateTime
                AND PlannedVisitStartTime < :endDateTime
                ORDER BY PlannedVisitStartTime ASC
            ];
        }

        return visits;
    }
    
    @AuraEnabled(cacheable=true)
    public static String checkIfUserCheckedIn() {
        Id currentUserId = UserInfo.getUserId();
        System.debug('currentUserId'+currentUserId);

        // Check if there's an Attendance__c record for the user with "Checked In" status on that date
        List<Attendance__c> attendanceList = [
            SELECT Id,Is_Checked_In__c
            FROM Attendance__c
            WHERE User__c = :currentUserId
            AND Is_Checked_In__c = true
            LIMIT 1
        ];
        System.debug('attendanceList'+attendanceList);

        if (attendanceList.isEmpty()) {
            return 'You must check in before Executing the visit.';
        }

        return 'Success';
    }
}