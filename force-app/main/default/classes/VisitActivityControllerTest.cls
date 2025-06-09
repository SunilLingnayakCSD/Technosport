@isTest
private class VisitActivityControllerTest {

    @isTest
    static void testGetVisitActivities() {
        
        Account visitAccount = new Account(Name = 'Visit Account',BillingPostalCode='273747',BillingCity='xys',BillingStreet='Karnataka');
        insert visitAccount;
    
        cgcloud__Visit_Template__c template = new cgcloud__Visit_Template__c(Name = 'Test Template');
        insert template;
        
        
         RetailStore store = new RetailStore(Name = 'Test Store', AccountId = visitAccount.Id);
        insert store;

        Visit visit = new Visit(AccountId = visitAccount.Id,PlaceId = store.Id,
        PlannedVisitStartTime = System.today(),cgcloud__Visit_Template__c=template.Id);
        insert visit;

        // Create a Visit Activity
        Visit_Activity__c activity = new Visit_Activity__c(
            Name = 'Test Activity',
            Data_Type__c = 'Text',
            Section__c = 'Attach & Upload Photo',
            Required__c = true,
            Take_Picture__c = false,
            Parent_Based_Visibility__c = false,
            Order_Related__c = false
        );
        insert activity;

        // Create an Answer and associate it to the activity (optional)
        Answer__c answer = new Answer__c(Name = 'Yes', Visit_Activity__c = activity.Id);
        insert answer;

        // Create Visit Question linking Template to Activity
        Visit_Question__c question = new Visit_Question__c(
            Visit_Template__c = template.Id,
            Visit_Activity__c = activity.Id
        );
        insert question;

        // Call the method
        Test.startTest();
        List<Visit_Activity__c> result = VisitActivityController.getVisitActivities(visit.Id);
        Test.stopTest();

        // Assertions
       //System.assertEquals(1, result.size(), 'Should return one activity');
        System.assertEquals(activity.Id, result[0].Id, 'Returned activity should match the inserted one');
        System.assertEquals('Test Activity', result[0].Name);
    }
    
    
    @isTest
    static void testGetPicklistAnswers() {
        // Step 1: Create the Visit Activity (Visit_Activity__c)
        Visit_Activity__c activity = new Visit_Activity__c(
            Name = 'Test Activity',
            Data_Type__c = 'Text',
            Section__c = 'Feedback',
            Required__c = true,
            Take_Picture__c = false,
            Parent_Based_Visibility__c = false,
            Order_Related__c = false
        );
        insert activity;

        // Step 2: Create the Answer records (Answer__c)
        Answer__c answer1 = new Answer__c(
            Name = 'Option 1', 
            Visit_Activity__c = activity.Id
        );
        Answer__c answer2 = new Answer__c(
            Name = 'Option 2', 
            Visit_Activity__c = activity.Id
        );
        insert new List<Answer__c>{ answer1, answer2 };

        // Step 3: Call the getPicklistAnswers method
        Test.startTest();
        List<String> picklistAnswers = VisitActivityController.getPicklistAnswers(activity.Id);
        Test.stopTest();

        // Step 4: Verify the returned values
        System.assertEquals(2, picklistAnswers.size(), 'There should be two answers');
        System.assert(picklistAnswers.contains('Option 1'), 'Picklist should contain "Option 1"');
        System.assert(picklistAnswers.contains('Option 2'), 'Picklist should contain "Option 2"');
    }
    
    
     @isTest
    static void testCreateVisitTasks() {
        
        Account visitAccount = new Account(Name = 'Visit Account',BillingPostalCode='273747',BillingCity='xys',BillingStreet='Karnataka');
        insert visitAccount;
        
        // Step 1: Create required related data
        cgcloud__Visit_Template__c template = new cgcloud__Visit_Template__c(Name = 'Test Template');
        insert template;
        
       
		RetailStore store = new RetailStore(Name = 'Test Store', AccountId = visitAccount.Id);
        insert store;
        Visit visit = new Visit(AccountId = visitAccount.Id,PlaceId = store.Id, PlannedVisitStartTime = Date.today());
        insert visit;

        VisitActivityController.VisitTaskWrapper wrapper1 = new VisitActivityController.VisitTaskWrapper();
        wrapper1.question = 'Question 1';
        wrapper1.answer = 'Answer 1';
        
        VisitActivityController.VisitTaskWrapper wrapper2 = new VisitActivityController.VisitTaskWrapper();
        wrapper2.question = 'Question 2';
        wrapper2.answer = 'Answer 2';
        
        List<VisitActivityController.VisitTaskWrapper> taskWrappers = new List<VisitActivityController.VisitTaskWrapper>{ wrapper1, wrapper2 };


        // Step 3: Serialize to JSON
        String jsonTasks = JSON.serialize(taskWrappers);

        // Step 4: Call the method
        Test.startTest();
        List<Id> insertedTaskIds = VisitActivityController.createVisitTasks(jsonTasks, visit.Id);
        Test.stopTest();

        // Step 5: Assertions
        System.assertEquals(2, insertedTaskIds.size(), 'Two Visit_Task__c records should be inserted.');

        // Optional: Validate that tasks are really in the database
        List<Visit_Task__c> tasks = [SELECT Id, Name, Vist_Answer__c FROM Visit_Task__c WHERE Visit__c = :visit.Id];
        System.assertEquals(2, tasks.size(), 'Should return 2 tasks from database.');
        System.assertEquals('Question 1', tasks[0].Name);
        System.assertEquals('Answer 1', tasks[0].Vist_Answer__c);
    }

    @isTest
    static void testUploadAttachment() {
        
        Account visitAccount = new Account(Name = 'Visit Account',BillingPostalCode='273747',BillingCity='xys',BillingStreet='Karnataka');
        insert visitAccount;
        
        // Step 1: Create a Visit (parent record)
        cgcloud__Visit_Template__c template = new cgcloud__Visit_Template__c(Name = 'Test Template');
        insert template;
        
       
		RetailStore store = new RetailStore(Name = 'Test Store', AccountId = visitAccount.Id);
        insert store;
        Visit visit = new Visit(AccountId = visitAccount.Id,PlaceId = store.Id, PlannedVisitStartTime = Date.today());
        insert visit;

        // Step 2: Prepare a base64-encoded string
        String originalText = 'This is a test file content';
        Blob fileBody = Blob.valueOf(originalText);
        String base64Data = EncodingUtil.base64Encode(fileBody);

        // Step 3: Call the method
        Test.startTest();
        VisitActivityController.uploadAttachment(visit.Id, base64Data, 'test_file.jpg');
        Test.stopTest();

        // Step 4: Verify that the attachment was inserted
        List<Attachment> attachments = [SELECT Id, Name, ParentId, Body FROM Attachment WHERE ParentId = :visit.Id];
        System.assertEquals(1, attachments.size(), 'One attachment should have been inserted.');
        System.assertEquals('test_file.jpg', attachments[0].Name);
        System.assertEquals(visit.Id, attachments[0].ParentId);
    }
    
    
     @isTest
    static void testCheckVisitTasksExistTrue() {
        
        Account visitAccount = new Account(Name = 'Visit Account',BillingPostalCode='273747',BillingCity='xys',BillingStreet='Karnataka');
        insert visitAccount;
        
        // Step 1: Create supporting records
        cgcloud__Visit_Template__c template = new cgcloud__Visit_Template__c(Name = 'Template A');
        insert template;
        
        RetailStore retailer = new RetailStore(Name = 'Test Store', AccountId = visitAccount.Id);
        insert retailer;
		
        Visit visit = new Visit(AccountId = visitAccount.Id,PlaceId = retailer.Id, PlannedVisitStartTime = Date.today());
        insert visit;

        // Step 2: Create a task linked to the Visit
        Visit_Task__c task = new Visit_Task__c(
            Name = 'Task 1',
            Visit__c = visit.Id,
            Vist_Answer__c = 'Sample Answer'
        );
        insert task;

        // Step 3: Call the method
        Test.startTest();
        Boolean exists = VisitActivityController.checkVisitTasksExist(visit.Id);
        Test.stopTest();

        System.assertEquals(true, exists, 'Task should exist for this Visit');
    }

    @isTest
    static void testCheckVisitTasksExistFalse() {
        
        Account visitAccount = new Account(Name = 'Visit Account',BillingPostalCode='273747',BillingCity='xys',BillingStreet='Karnataka');
        insert visitAccount;
        
        // Step 1: Create supporting Visit without any tasks
        cgcloud__Visit_Template__c template = new cgcloud__Visit_Template__c(Name = 'Template B');
        insert template;
        
        RetailStore retailer = new RetailStore(Name = 'Test Store', AccountId = visitAccount.Id);
        insert retailer;
		
        Visit visit = new Visit(AccountId = visitAccount.Id,PlaceId = retailer.Id, PlannedVisitStartTime = Date.today());
        insert visit;

        // Step 2: Call the method
        Test.startTest();
        Boolean exists = VisitActivityController.checkVisitTasksExist(visit.Id);
        Test.stopTest();

        System.assertEquals(false, exists, 'No tasks should exist for this Visit');
    }

}