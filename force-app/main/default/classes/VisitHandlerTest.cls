@isTest
private class VisitHandlerTest {

    // Helper method to create test user with necessary permissions
    private static User createTestUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        return new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test.user@example.com',
            Username = 'test.userabc' + System.currentTimeMillis() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
        );
    }

    @isTest
    static void testCompletedVisitInsertsAndUpdates() {
        User asmUser = createTestUser();
        insert asmUser;
        
        Account testAccount = new Account(Name = 'Test Account', BillingPostalCode = '577456', Phone = '9988770000');
        insert testAccount;
        
        RetailStore testRetailer = new RetailStore(AccountId = testAccount.Id, Name = 'Test RetailStore1');
        insert testRetailer;

        ASM_AOP_Target__c target = new ASM_AOP_Target__c(Sales_Rep__c = asmUser.Id);
        insert target;

        Test.startTest();

        Visit v1 = new Visit(
            Status = 'Completed',
            PlannedVisitEndTime = System.now(),
            PlannedVisitStartTime = System.now().addHours(-2),
            ActualVisitStartTime = System.now().addHours(-2),
            ActualVisitEndTime = System.now(),
            cgcloud__Responsible__c = asmUser.Id,
            AccountId = testAccount.Id,
            PlaceId = testRetailer.Id
        );
        insert v1;

        Visit v2 = new Visit(
            Status = 'Planned',
            PlannedVisitStartTime = System.now().addHours(-1),
            PlannedVisitEndTime = System.now(),
            ActualVisitStartTime = System.now().addHours(-1),
            ActualVisitEndTime = System.now(),
            cgcloud__Responsible__c = asmUser.Id,
            AccountId = testAccount.Id,
            PlaceId = testRetailer.Id
        );
        insert v2;
        
        v2.Status = 'Completed';
        Map<Id, Visit> oldMap = new Map<Id, Visit>{v2.Id => new Visit(Id=v2.Id, Status='Planned')};
        VisitHandler.handleTrigger(new List<Visit>{v2}, oldMap, false, true);

        Test.stopTest();

        ASM_AOP_Target__c updatedTarget = [
            SELECT January_MTD_visits__c, WTD_Visits__c, Day_visits__c, 
                January_Total_Unique_Visits_MTD__c, Daily_Average__c
            FROM ASM_AOP_Target__c 
            WHERE Id = :target.Id
            LIMIT 1
        ];
        
        // System.assertEquals(2, updatedTarget.January_MTD_visits__c, 'MTD visits mismatch');
        System.assertEquals(2, updatedTarget.WTD_Visits__c, 'WTD visits mismatch');
        System.assertEquals(2, updatedTarget.Day_visits__c, 'Day visits mismatch');
        // System.assertEquals(1, updatedTarget.January_Total_Unique_Visits_MTD__c, 'Unique visits mismatch');
        // System.assertEquals(0.2, updatedTarget.Daily_Average__c, 'Daily average mismatch');

        User updatedUser = [SELECT Total_Unique_Visits__c FROM User WHERE Id = :asmUser.Id];
        System.assertEquals(1, updatedUser.Total_Unique_Visits__c, 'Lifetime unique visits mismatch');
    }

    @isTest
    static void testPriorVisitsAndUniqueness() {
        User asmUser = createTestUser();
        insert asmUser;
        
        Account testAccount = new Account(Name = 'Test Account', BillingPostalCode = '577456', Phone = '9988770000');
        insert testAccount;
        
        RetailStore testRetailer2 = new RetailStore(AccountId = testAccount.Id, Name = 'Test RetailStore2');
        insert testRetailer2;

        Visit priorVisit = new Visit(
            PlannedVisitEndTime = System.now(),
            PlannedVisitStartTime = System.now().addHours(-2),
            Status = 'Completed',
            ActualVisitStartTime = System.now().addDays(-5).addHours(-2),
            ActualVisitEndTime = System.now().addDays(-5),
            cgcloud__Responsible__c = asmUser.Id,
            AccountId = testAccount.Id,
            PlaceId = testRetailer2.Id
        );
        insert priorVisit;

        Test.startTest();

        Visit v = new Visit(
            Status = 'Completed',
            ActualVisitStartTime = System.now(),
            ActualVisitEndTime = System.now(),
            cgcloud__Responsible__c = asmUser.Id,
            AccountId = testAccount.Id,
            PlaceId = testRetailer2.Id
        );
        insert v;
        VisitHandler.handleTrigger(new List<Visit>{v}, null, true, false);

        Test.stopTest();

        ASM_AOP_Target__c updatedTarget = [
            SELECT January_Total_Unique_Visits_MTD__c
            FROM ASM_AOP_Target__c 
            WHERE Sales_Rep__c = :asmUser.Id
            LIMIT 1
        ];
        System.assertEquals(1, updatedTarget.January_Total_Unique_Visits_MTD__c, 'Should not count duplicate account');
    }

    @isTest
    static void testMonthlyFieldCoverage() {
        for(Integer month = 1; month <= 12; month++) {
            User asmUser = createTestUser();
            insert asmUser;
            
            Account testAccount2 = new Account(Name = 'Test Account2 ' + month, BillingPostalCode = '577456', Phone = '9988110000');
            insert testAccount2;

            RetailStore testRetailer3 = new RetailStore(AccountId = testAccount2.Id, Name = 'Test RetailStore3 ' + month);
            insert testRetailer3;

            Date testDate = Date.newInstance(2025, month, 15);
            DateTime.newInstance(testDate, Time.newInstance(10,0,0,0));

            Visit v = new Visit(
                Status = 'Completed',
                PlannedVisitStartTime = DateTime.newInstance(testDate, Time.newInstance(13,0,0,0)),
                PlannedVisitEndTime = DateTime.newInstance(testDate, Time.newInstance(14,0,0,0)),
                ActualVisitStartTime = DateTime.newInstance(testDate, Time.newInstance(13,0,0,0)),
                ActualVisitEndTime = DateTime.newInstance(testDate, Time.newInstance(14,0,0,0)),
                cgcloud__Responsible__c = asmUser.Id,
                AccountId = testAccount2.Id,
                PlaceId = testRetailer3.Id
            );
            insert v;
            VisitHandler.handleTrigger(new List<Visit>{v}, null, true, false);

            ASM_AOP_Target__c target = [
                SELECT January_MTD_visits__c, February_MTD_Visits__c, March_MTD_Visits__c,
                    April_MTD_Visits__c, May_MTD_Visits__c, June_MTD_Visits__c,
                    July_MTD_Visits__c, August_MTD_Visits__c, September_MTD_Visits__c,
                    October_MTD_visits__c, November_MTD_Visits__c, December_MTD_visits__c
                FROM ASM_AOP_Target__c 
                WHERE Sales_Rep__c = :asmUser.Id
                LIMIT 1
            ];

            String fieldName = getMonthFieldName(month) + '__c';
            System.assertEquals(1, target.get(fieldName), 'MTD field for month ' + month + ' not updated');
        }
    }

    // Helper to get month field name
    private static String getMonthFieldName(Integer month) {
        Map<Integer, String> monthMap = new Map<Integer, String>{
            1 => 'January_MTD_visits',
            2 => 'February_MTD_Visits',
            3 => 'March_MTD_Visits',
            4 => 'April_MTD_Visits',
            5 => 'May_MTD_Visits',
            6 => 'June_MTD_Visits',
            7 => 'July_MTD_Visits',
            8 => 'August_MTD_Visits',
            9 => 'September_MTD_Visits',
            10 => 'October_MTD_visits',
            11 => 'November_MTD_Visits',
            12 => 'December_MTD_visits'
        };
        return monthMap.get(month);
    }
}