@isTest
private class TestOrderCountApexClass {

    @isTest
    static void testGetOrderDetails() {
       
        Account testAccount = new Account(Name = 'Test Account',BillingPostalCode='273747',BillingCity='xys',BillingStreet='Karnataka');
        insert testAccount;

        // Create Contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;

        // Create User with ContactId
        Profile p = [SELECT Id FROM Profile WHERE Name='Community Distributor Access' LIMIT 1];
        User testUser = new User(
            Username = 'testuser123@kkexample.com',
            Email = 'testuser123@example.com',
            Alias = 'tuser',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ContactId = testContact.Id
        );
        testUser.FirstName = 'Test';
        testUser.LastName = 'User';
        testUser.UserRoleId = null;
        testUser.IsActive = true;
        testUser.CompanyName = 'Test Company';
        testUser.Title = 'Tester';
        testUser.Division = 'Sales';
        testUser.Department = 'QA';
        testUser.EmployeeNumber = '123';
        insert testUser;

        // Set current user context
        System.runAs(testUser) {
            // Create RecordType for Order
           Id orderRecordTypeId = SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Purchase_Order').getRecordTypeId();

            // Create Product
            Product2 product = new Product2(Name = 'Test Product', IsActive = true);
            insert product;

            // Create Pricebook
           Pricebook2 standardPB = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPB;

            // Create PricebookEntry
            PricebookEntry pbe = new PricebookEntry(
                Product2Id = product.Id,
                Pricebook2Id = standardPB.Id,
                UnitPrice = 100,
                IsActive = true
            );
            insert pbe;

            // Create Order
            Order order = new Order(
                AccountId = testAccount.Id,
                EffectiveDate = Date.today(),
                Pricebook2Id = standardPB.Id, 
                Status = 'Draft',
                RecordTypeId = orderRecordTypeId
            );
            insert order;

            // Create OrderItem
            OrderItem oi = new OrderItem(
                OrderId = order.Id,
                Quantity = 2,
                UnitPrice = 100,
                PricebookEntryId = pbe.Id
            );
            insert oi;

            // Create Quotes
            Quote q1 = new Quote(Name = 'Quote 1', Status = 'Invoice', OrderId__c = order.Id);
            Quote q2 = new Quote(Name = 'Quote 2', Status = 'Reserved', OrderId__c = order.Id);
            insert new List<Quote>{ q1, q2 };
	Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());
            // Step 2: Call method
            Test.startTest();
            List<OrderCountApexClass.OrderWrapper> result = OrderCountApexClass.getOrderDetails();
            Test.stopTest();

            // Step 3: Assert
            System.assertEquals(1, result.size(), 'There should be 1 wrapper for the Order.');
            //System.assertEquals(1, result[0].quoteInInvoice, 'There should be 1 quote with Invoice status.');
            System.assertEquals(1, result[0].quoteNotInInvoice, 'There should be 1 quote with Reserved status.');
            System.assertEquals(order.Id, result[0].orderId, 'Order ID should match.');
            System.assertNotEquals(null, result[0].orderLineItem, 'Order line items should not be null.');
            System.assertEquals(1, result[0].orderLineItem.size(), 'There should be one order line item.');
        }
    }

    @isTest
    static void testNoContactOnUser() {
        // User with no ContactId
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User userWithoutContact = new User(
            Username = 'no.contact@example.com',
            Email = 'no.contact@example.com',
            Alias = 'nocont',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName='testuser3'
        );
        insert userWithoutContact;

        System.runAs(userWithoutContact) {
            Test.startTest();
            List<OrderCountApexClass.OrderWrapper> result = OrderCountApexClass.getOrderDetails();
            Test.stopTest();
            System.assertEquals(0, result.size(), 'Should return empty list if no contact.');
        }
    }

    @isTest
    static void testNoAccountOnContact() {
        // Contact without Account
       Account testAccount = new Account(Name = 'Test Account',BillingPostalCode='273747',BillingCity='xys',BillingStreet='Karnataka');
        insert testAccount;

        // Create Contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;

        Profile p = [SELECT Id FROM Profile WHERE Name='Community Distributor Access' LIMIT 1];
        User testUser = new User(
            Username = 'no.account@example.com',
            Email = 'no.account@example.com',
            Alias = 'noacct',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Chicago',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ContactId = testContact.Id,
            LastName='Testuser7'
            
        );
        insert testUser;

        System.runAs(testUser) {
            Test.startTest();
            List<OrderCountApexClass.OrderWrapper> result = OrderCountApexClass.getOrderDetails();
            Test.stopTest();
            System.assertEquals(0, result.size(), 'Should return empty list if no account.');
        }
    }
}