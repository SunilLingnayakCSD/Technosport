@isTest
public class VisitControllerTest {

    @testSetup
    static void setupData() {
        Account visitAccount = new Account(Name = 'Visit Account', BillingPostalCode = '273747',BillingCity='xys',BillingStreet='Karnataka');
        insert visitAccount;

        cgcloud__Visit_Template__c template = new cgcloud__Visit_Template__c(Name = 'test');
        insert template;

        Product2 prod = new Product2(Name = 'Test Product', IsActive = true, Product_Type1__c = 'Product Template');
        insert prod;

        RecordType visitActivityRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Visit_Activity__c' AND DeveloperName = 'Survey' LIMIT 1];
        RecordType visitTaskRt = [SELECT Id FROM RecordType WHERE SObjectType = 'Visit_Task__c' AND DeveloperName = 'Survey' LIMIT 1];

        RetailStore store = new RetailStore(Name = 'Test Store', AccountId = visitAccount.Id);
        insert store;

        Visit visit = new Visit(
            AccountId = visitAccount.Id,
            PlaceId = store.Id,
            PlannedVisitStartTime = System.today(),
            Is_Checked_In__c = true,
            Is_Checked_out__c = false
        );
        insert visit;

        Visit_Activity__c activity = new Visit_Activity__c(
            Name = 'Survey Activity',
            Visit_Template__c = template.Id,
            Product__c = prod.Id,
            RecordTypeId = visitActivityRt.Id
        );
        insert activity;
    }

    @isTest
    static void testGetAllProducts() {
        Test.startTest();
        List<Product2> products = VisitController.getAllProducts();
        Test.stopTest();

        System.assert(!products.isEmpty(), 'Should return at least one active product template');
    }

    @isTest
    static void testGetSurveyActivities() {
        cgcloud__Visit_Template__c template = [SELECT Id FROM cgcloud__Visit_Template__c LIMIT 1];

        Test.startTest();
        List<Visit_Activity__c> activities = VisitController.getSurveyActivities(template.Id);
        Test.stopTest();

        System.assertEquals(1, activities.size(), 'One survey activity should be returned');
    }

    @isTest
    static void testCreateVisitTaskSuccess() {
        Product2 prod = [SELECT Id, Name FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
        Visit activity = [SELECT Id FROM Visit  LIMIT 1];

        String tagImage = JSON.serialize(new Map<String, Object>{
            'fileName' => 'tag.jpg',
            'base64' => EncodingUtil.base64Encode(Blob.valueOf('tag image content'))
        });

        Test.startTest();
        String taskId = VisitController.createVisitTask(
            prod.Id, 'Great feedback', activity.Id, prod.Name, 'Batch123', tagImage
        );
        Test.stopTest();

        Visit_Task__c task = [SELECT Id, Feedback__c FROM Visit_Task__c WHERE Id = :taskId];
        System.assertEquals('Great feedback', task.Feedback__c);
    }

    @isTest
    static void testCreateVisitTask_DuplicateCheck() {
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Visit activity = [SELECT Id FROM Visit LIMIT 1];
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Visit_Task__c' AND DeveloperName = 'Survey' LIMIT 1];

        Visit_Task__c existingTask = new Visit_Task__c(
            Product__c = prod.Id,
            Feedback__c = 'First Feedback',
            Visit__c = activity.Id,
            Name = 'Test Product',
            RecordTypeId = rt.Id
        );
        insert existingTask;

        Test.startTest();
        try {
            VisitController.createVisitTask(prod.Id, 'Duplicate Feedback', activity.Id, 'Test Product', null, null);
            System.assert(false, 'Expected duplicate exception');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('already submitted'));
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateVisitTask_MissingParams() {
        Test.startTest();
        try {
            VisitController.createVisitTask(null, '', null, null, null, null);
            System.assert(false, 'Expected exception due to missing parameters');
        } catch (AuraHandledException e) {
           // System.assert(e.getMessage().contains('required'), 'Expected missing param error');
        }
        Test.stopTest();
    }

    @isTest
    static void testSaveAttachmentToVisitTask() {
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        Visit activity = [SELECT Id FROM Visit LIMIT 1];
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Visit_Task__c' AND DeveloperName = 'Survey' LIMIT 1];

        Visit_Task__c task = new Visit_Task__c(
            Product__c = prod.Id,
            Feedback__c = 'Feedback for file',
            Visit__c = activity.Id,
            Name = 'Test Product',
            RecordTypeId = rt.Id
        );
        insert task;

        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('dummy file content'));
        String fileName = 'TestFile.txt';

        Test.startTest();
        VisitController.saveAttachmentToVisitTask(fileName, base64Data, 'text/plain', task.Id);
        Test.stopTest();

        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :task.Id];
        System.assert(!links.isEmpty(), 'Attachment should be linked to visit task');
    }

    @isTest
    static void testGetCheckedVisits() {
        Visit visit = [SELECT Id FROM Visit WHERE Is_Checked_In__c = true LIMIT 1];

        Test.startTest();
        List<Visit> visits = VisitController.getCheckedVisits(visit.Id);
        Test.stopTest();

        System.assertEquals(1, visits.size(), 'Should return one checked-in visit');
        System.assert(visits[0].Is_Checked_In__c, 'Visit should be checked-in');
    }
}