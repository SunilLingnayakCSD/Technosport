public with sharing class SaveAttachmentController {
public class VisitTaskWrapper {
        public String question;
        public String answer;
        public String questionId;
    }
    @AuraEnabled
    public static String saveAttachment(String recordId, String base64Data, String fileName) {
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = fileName;
        contentVersion.PathOnClient = fileName; 
        contentVersion.VersionData = EncodingUtil.base64Decode(base64Data);  
        contentVersion.FirstPublishLocationId = recordId; 

        insert contentVersion;

        return contentVersion.Id;
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
            Visit_Activity__r.Order_Related__c,
            Visit_Activity__r.Take_Picture__c
        FROM Visit_Question__c
        WHERE Visit_Template__c = :templateId
        AND Visit_Activity__r.Id != null
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
        // a.ContentType = 'image/jpeg';
        insert a;
    }
    
    @AuraEnabled(cacheable = true)
    public static List<Account> getAccounts() {
        Id retailerRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Customer' AND SObjectType = 'Account' LIMIT 1].Id;

        List<Account> retailerAccounts = [SELECT Id, Name,Phone,Distributor__c, RecordTypeId FROM Account WHERE RecordTypeId = :retailerRecordTypeId];

        return retailerAccounts;
    }
    
    @AuraEnabled
public static Visit getLastVisitDate(Id accountId) {
    System.debug('accountId'+accountId);
    Visit lastVisit = [
        SELECT Id, cgcloud__Completed_Date__c 
        FROM Visit 
        WHERE AccountId = :accountId AND cgcloud__Completed_Date__c !=null
        ORDER BY cgcloud__Completed_Date__c DESC 
        LIMIT 1
    ];    
     if (lastVisit !=null) {
        return lastVisit;
    }
    
    return null; 
}
    
    @AuraEnabled
public static Id createOrderRecord(String distributorName, Id retailerId, Id visitId, String orderValue,Date lastvisitDate,String orderTypeValue, String base64Image, String fileName) {
    Order order = new Order();
    order.Status = 'Draft';
    order.Distributor_Name__c = distributorName;
    order.AccountId = retailerId;
    order.Order_Amount__c = Decimal.valueOf(orderValue);
    order.EffectiveDate = System.today();
    order.Order_Type__c = orderTypeValue;
    order.isASMorder__c  = true;
    order.Visit__c=visitId;

    insert order;

    if (String.isNotBlank(base64Image) && String.isNotBlank(fileName)) {
    ContentVersion contentVersion = new ContentVersion();
    contentVersion.Title = fileName;
    contentVersion.PathOnClient = fileName;
    contentVersion.VersionData = EncodingUtil.base64Decode(base64Image);
    // contentVersion.ContentType = 'image/jpeg';
    insert contentVersion;

    // Optionally relate it to a record (e.g., Order) using ContentDocumentLink
    ContentVersion insertedVersion = [
        SELECT Id, ContentDocumentId 
        FROM ContentVersion 
        WHERE Id = :contentVersion.Id 
        LIMIT 1
    ];

    ContentDocumentLink link = new ContentDocumentLink();
    link.ContentDocumentId = insertedVersion.ContentDocumentId;
    link.LinkedEntityId = order.Id; // Relating to the Order record
    link.ShareType = 'V'; // Viewer access
    link.Visibility = 'AllUsers';
    insert link;
}


    return order.Id;
}


}