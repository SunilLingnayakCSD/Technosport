public with sharing class invoicepopupController {
@AuraEnabled(cacheable=true)
public static List<Attendance__c> getLocation(Id recordId) {
    // Query to get the Attendance record
    return [
        SELECT Latitude__c, Longitude__c
        FROM Attendance__c
        WHERE Id = :recordId
        LIMIT 1
    ];
}
    
    @AuraEnabled(cacheable=true)
public static List<Visit> getvisitLocation(Id recordId) {
    // Query to get the Attendance record
    return [
        SELECT Id,Name,Latitude__c,Longitude__c FROM Visit 
        WHERE Id = :recordId
        LIMIT 1
    ];
}

}