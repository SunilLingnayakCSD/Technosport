public with sharing class VisitActivityController {
    
    public class VisitTaskWrapper {
        public String question;
        public String answer;
        public String questionId;
    }

@AuraEnabled(cacheable=true)
public static List<Visit_Activity__c> getVisitActivities(Id visitId) {
    Visit visitRecord = [
        SELECT cgcloud__Visit_Template__c 
        FROM Visit 
        WHERE Id = :visitId 
        LIMIT 1
    ];

    Id templateId = visitRecord.cgcloud__Visit_Template__c;

    List<Visit_Question__c> visitQuestions = [
        SELECT 
            Visit_Activity__r.Id,
            Visit_Activity__r.Name,
            Visit_Activity__r.Data_Type__c,
            Visit_Activity__r.Section__c,
            Visit_Activity__r.Required__c,
            Visit_Activity__r.Take_Picture__c,
            Visit_Activity__r.Parent_Based_Visibility__c,
            Visit_Activity__r.Visit_Activity__c,
            Visit_Activity__r.Answer__r.Name // Changed to get Answer Name
        FROM Visit_Question__c
        WHERE Visit_Template__c = :templateId
        AND Visit_Activity__r.Id != null AND Visit_Activity__r.Order_Related__c=FALSE
        ORDER BY Visit_Activity__r.Section__c
    ];

    Set<Id> seenIds = new Set<Id>();
    List<Visit_Activity__c> activities = new List<Visit_Activity__c>();

    for (Visit_Question__c vq : visitQuestions) {
        Visit_Activity__c activity = vq.Visit_Activity__r;
        if (activity != null && !seenIds.contains(activity.Id)) {
            activities.add(activity);
            seenIds.add(activity.Id);
        }
    }

    return activities;
}




    @AuraEnabled(cacheable=true)
    public static List<String> getPicklistAnswers(Id visitActivityId) {
        List<String> values = new List<String>();
        for (Answer__c ans : [
            SELECT Name FROM Answer__c WHERE Visit_Activity__c = :visitActivityId
        ]) {
            values.add(ans.Name);
        }
        return values;
    }

    @AuraEnabled
    public static List<Id> createVisitTasks(String taskJson, Id visitId) {
        List<VisitTaskWrapper> tasks = (List<VisitTaskWrapper>) JSON.deserialize(taskJson, List<VisitTaskWrapper>.class);

        List<Visit_Task__c> toInsert = new List<Visit_Task__c>();
        for (VisitTaskWrapper task : tasks) {
            if (String.isNotBlank(task.question) && String.isNotBlank(task.answer)) {
                toInsert.add(new Visit_Task__c(
                    Visit__c = visitId,
                    Name = task.question,
                    Vist_Answer__c = task.answer
                ));
            }
        }

        insert toInsert;

        // Collect and return inserted record Ids
        List<Id> insertedIds = new List<Id>();
        for (Visit_Task__c vt : toInsert) {
            insertedIds.add(vt.Id);
        }
        return insertedIds;
    }

    @AuraEnabled
    public static void uploadAttachment(String parentId, String base64Data, String fileName) {
        Attachment a = new Attachment();
        a.ParentId = parentId;
        a.Name = fileName;
        a.Body = EncodingUtil.base64Decode(base64Data);
        a.ContentType = 'image/jpeg';
        insert a;
    }

    @AuraEnabled
    public static Boolean checkVisitTasksExist(Id visitId) {
        return [SELECT Id FROM Visit_Task__c WHERE Visit__c = :visitId LIMIT 1].size() > 0;
    }
}