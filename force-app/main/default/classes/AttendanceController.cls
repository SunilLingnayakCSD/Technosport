public class AttendanceController {
    @AuraEnabled(cacheable=false)
   public static List<Attendance__c> getCheckedAttendances(Id ownerId) {
        List<Attendance__c> attend = [
            SELECT Id, Name, Is_Checked_In__c, OwnerId,Check_In__c,CreatedDate
            FROM Attendance__c 
            WHERE  OwnerId = :ownerId 
            ORDER BY CreatedDate DESC
        ];
            return attend;
    }
}