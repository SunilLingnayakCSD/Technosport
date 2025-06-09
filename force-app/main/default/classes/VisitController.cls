public with sharing class VisitController {
    
    @AuraEnabled(cacheable=true)
    public static List<Product2> getAllProducts(){
        return[
           SELECT Id,Name From 
            Product2 Where Product_Type1__c = 'Product Template' 
            AND IsActive =true
        ];
    }
    
    
    @AuraEnabled(cacheable=true)
    public static List<Visit_Activity__c> getSurveyActivities(Id visitTemplateId) {
        String surveyRecordTypeId = Schema.SObjectType.Visit_Activity__c.getRecordTypeInfosByDeveloperName()
            .get('Survey').getRecordTypeId();
        
        return [
            SELECT Id, Name, Product__c, Product__r.Name, Product__r.Description, 
                   Product__r.Family, Product__r.ProductCode, Product__r.URL__c,
                   Product__r.HSN_SAC_Code__c
            FROM Visit_Activity__c 
            WHERE Visit_Template__c = :visitTemplateId 
            AND RecordTypeId = :surveyRecordTypeId
        ];
    }
    
    @AuraEnabled
    public static String createVisitTask(
        Id productId,
    String feedback,
    Id activityId,
    String productname,
    String productChange,
    String tagImage
        
    ) {
        System.debug('productId: ' + productId +
            ' feedback: ' + feedback +
            ' activityId: ' + activityId +
            ' productChange: ' + productChange);
        
        if (String.isBlank(feedback) || productId == null || activityId == null || productname == null) {
            throw new AuraHandledException('Product, feedback, and activity ID are required.');
        }
        RecordType rt;
        try {
            rt = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'Visit_Task__c'
            AND DeveloperName = 'Survey'
            LIMIT 1
        ];
        } catch (Exception e) {
            throw new AuraHandledException('RecordType "Survey" not found on Visit_Task__c.');
        }
        List<Visit_Task__c> existingTasks = [
        SELECT Id FROM Visit_Task__c
        WHERE Product__c = :productId AND Visit__c = :activityId
        LIMIT 1
    ];
        
        if (!existingTasks.isEmpty()) {
            throw new AuraHandledException('Feedback already submitted for this product.');
        }
        Visit_Task__c newTask = new Visit_Task__c(
            Product__c = productId,
        Feedback__c = feedback,
        Product_Batch__c = productChange,
        Visit__c = activityId,
        Name = productname,
        RecordTypeId = rt.Id
            );
        
        try {
            insert newTask;
            System.debug('Visit Task created successfully: ' + newTask.Id);
            Map<String, Object> tagFile = new Map<String, Object>();
            if (!String.isBlank(tagImage)) {
                tagFile = (Map<String, Object>) JSON.deserializeUntyped(tagImage);
            }
            List<ContentVersion> contentVersions = new List<ContentVersion>();

            if (!tagFile.isEmpty()) {
                ContentVersion tagCV = new ContentVersion();
                tagCV.VersionData = EncodingUtil.base64Decode((String) tagFile.get('base64'));
                tagCV.Title = (String) tagFile.get('fileName');
                tagCV.PathOnClient = '/' + (String) tagFile.get('fileName');
                tagCV.Origin = 'H';
                contentVersions.add(tagCV);
            }
        
            if (!contentVersions.isEmpty()) {
                insert contentVersions;
                
                List<ContentDocumentLink> links = new List<ContentDocumentLink>();
                for (ContentVersion cv : contentVersions) {
                    Id docId = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1
        ].ContentDocumentId;
                    
                    links.add(new ContentDocumentLink(
                        ContentDocumentId = docId,
                    LinkedEntityId = newTask.Id,
                    ShareType = 'V'
                        ));
                }
                insert links;
                
            }
            return newTask.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error creating Visit Task: ' + e.getMessage());
        }
    }
    @AuraEnabled
    public static void saveAttachmentToVisitTask(String fileName, String base64Data, String contentType, Id visitTaskId) {
        if (String.isBlank(fileName) || String.isBlank(base64Data) || String.isBlank(contentType) || String.isBlank(visitTaskId)) {
            throw new AuraHandledException('Missing required data to upload attachment.');
        }
    
        try {
          
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = '/' + fileName;
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            cv.Origin = 'H';
            insert cv;
    
            ContentVersion insertedCV = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
    
            ContentDocumentLink link = new ContentDocumentLink();
            link.ContentDocumentId = insertedCV.ContentDocumentId;
            link.LinkedEntityId = visitTaskId;
            link.ShareType = 'V';
            link.Visibility = 'AllUsers'; 
            insert link;
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to upload file: ' + e.getMessage());
        }
    }
    
    
    
    @AuraEnabled(cacheable=true)
    public static List<Visit> getCheckedVisits(Id recordId) {
        List<Visit> attend = [
            SELECT Id, Name, Is_Checked_In__c,Is_Checked_out__c, OwnerId,ActualVisitStartTime,CreatedDate
            FROM Visit 
            WHERE  Id = :recordId 
            ORDER BY CreatedDate DESC
        ];
        return attend;
    }
    
}