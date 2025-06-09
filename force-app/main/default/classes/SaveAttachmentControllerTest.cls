@isTest
public class SaveAttachmentControllerTest {

    private static Visit createTestVisit() {
         Account visitAccount = new Account(Name = 'Visit Account',BillingPostalCode='273747',BillingCity='xys',BillingStreet='Karnataka');
        insert visitAccount;
       cgcloud__Visit_Template__c template = new cgcloud__Visit_Template__c(Name = 'Test Template');
        insert template;

       RetailStore store = new RetailStore(Name = 'Test Store', AccountId = visitAccount.Id);
        insert store;

        Visit testVisit = new Visit(AccountId = visitAccount.Id,PlaceId = store.Id,
        PlannedVisitStartTime = System.today(),cgcloud__Visit_Template__c=template.Id);
        insert testVisit;
       
        return testVisit;
    }

    private static Account createTestAccount() {
        RecordType rt;
        try {
            rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Distributor' LIMIT 1];
        } catch (Exception e) {
           // rt = new RecordType(SObjectType = 'Account', DeveloperName = 'Distributor', Name = 'Distributor');
           // insert rt;
        }

        Account distributor = new Account(
            Name = 'Distributor',
            Phone = '9999999999',
            BillingPostalCode = '100001',
            RecordTypeId = rt.Id,BillingCity='xys',BillingStreet='Karnataka'
        );
        insert distributor;

        Account testAccount = new Account(
            Name = 'Retailer',
            Phone = '1234567890',
            Distributor__c = distributor.Id,
            BillingPostalCode = '100002',BillingCity='xys',BillingStreet='Karnataka'
        );
        insert testAccount;
        return testAccount;
    }

    private static void createVisitActivitiesData(Visit visit) {
        Visit_Activity__c activity = new Visit_Activity__c(
            Name = 'Activity 1',
            Data_Type__c = 'Text',
            Order_Related__c = false,
            Take_Picture__c = false
        );
        insert activity;

        Visit_Question__c question = new Visit_Question__c(
            Visit_Template__c = visit.cgcloud__Visit_Template__c,
            Visit_Activity__c = activity.Id
        );
        insert question;
    }

    @isTest
    public static void testSaveAttachment() {
        Account account = createTestAccount();
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test Attachment'));
        String fileName = 'TestFile.txt';

        Test.startTest();
        String attachmentId = SaveAttachmentController.saveAttachment(account.Id, base64Data, fileName);
        Test.stopTest();

        System.assertNotEquals(null, attachmentId);
    }

    @isTest
    public static void testGetVisitActivities() {
        Visit visit = createTestVisit();
        createVisitActivitiesData(visit);

        Test.startTest();
        List<Visit_Activity__c> activities = SaveAttachmentController.getVisitActivities(visit.Id);
        Test.stopTest();

        System.assert(activities.size() > 0, 'Expected at least one activity returned');
    }

    @isTest
    public static void testCreateVisitTasks() {
        Visit visit = createTestVisit();

        List<Map<String, String>> tasks = new List<Map<String, String>>{
            new Map<String, String>{'question' => 'Q1', 'answer' => 'A1', 'questionId' => '1'},
            new Map<String, String>{'question' => 'Q2', 'answer' => 'A2', 'questionId' => '2'}
        };

        String taskJson = JSON.serialize(tasks);

        Test.startTest();
        List<Id> ids = SaveAttachmentController.createVisitTasks(taskJson, visit.Id);
        Test.stopTest();

        System.assertEquals(2, ids.size());
    }

    @isTest
    public static void testUploadAttachment() {
        Account account = createTestAccount();
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Image Content'));
        String fileName = 'TestImage.jpg';

        Test.startTest();
        SaveAttachmentController.uploadAttachment(account.Id, base64Data, fileName);
        Test.stopTest();

        List<Attachment> attachments = [SELECT Id FROM Attachment WHERE ParentId = :account.Id];
        System.assertEquals(1, attachments.size());
    }

    @isTest
    public static void testGetAccounts() {
        createTestAccount(); // to ensure at least one account exists with RecordType

        Test.startTest();
        List<Account> accounts = SaveAttachmentController.getAccounts();
        Test.stopTest();

        System.assert(accounts.size() > 0, 'Expected retailer accounts to be returned');
    }

    @isTest
    public static void testGetLastVisitDate() {
        Account account = createTestAccount();
        Visit visit = new Visit(AccountId = account.Id, cgcloud__Completed_Date__c = System.today(),PlannedVisitStartTime = System.today());
        insert visit;

        Test.startTest();
        Date result = SaveAttachmentController.getLastVisitDate(account.Id);
        Test.stopTest();

        System.assertEquals(System.today(), result);
    }

    @isTest
    public static void testCreateOrderRecord() {
        Account account = createTestAccount();
        String base64Image = EncodingUtil.base64Encode(Blob.valueOf('Order Image'));
        String fileName = 'OrderImg.jpg';

        Test.startTest();
        Id orderId = SaveAttachmentController.createOrderRecord(
            'Distributor Inc', account.Id, null, '150.50', System.today(), 'TD Order', base64Image, fileName
        );
        Test.stopTest();

        Order o = [SELECT Id, Order_Amount__c FROM Order WHERE Id = :orderId LIMIT 1];
        System.assertEquals(150.50, o.Order_Amount__c);

        List<Attachment> atts = [SELECT Id FROM Attachment WHERE ParentId = :orderId];
        System.assertEquals(1, atts.size(), 'Expected one attachment for order');
    }
}