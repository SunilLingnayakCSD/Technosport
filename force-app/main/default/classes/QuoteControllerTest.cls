@isTest
public class QuoteControllerTest {

    // Reusable Mock class
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if (req.getEndpoint().contains('auth')) {
                res.setBody('{"jsonrpc": "2.0", "id": 1, "result": "fake_session_cookie"}');
                res.setHeader('Set-Cookie', 'fake_session_cookie=123456; Path=/; HttpOnly');
            } else {
                res.setBody('{"success": true}');
            }
            res.setStatusCode(200);
            return res;
        }
    }

    @testSetup
    static void setupData() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Create Account
        Account acc = new Account(
            Name = 'Test Account',
            BillingPostalCode = '273747',
            BillingCity = 'xys',
            BillingStreet = 'Karnataka'
        );
        insert acc;

        // Create Contact
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = acc.Id,
            Email = 'testuser@example.com'
        );
        insert con;

        // Create User
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Community Distributor Access' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ContactId = con.Id
        );
        insert u;

        System.runAs(u) {
            // Create Product Template and Variant
            Product2 prodTemplate = new Product2(Name = 'Test Product Template', ProductCode = 'TPT001', IsActive = true);
            insert prodTemplate;

            Product2 prodVariant = new Product2(
                Name = 'Test Product Variant',
                ProductCode = 'TPV001',
                Product_Template__c = prodTemplate.Id,
                IsActive = true
            );
            insert prodVariant;

            // Pricebook Entries
            Id standardPBId = Test.getStandardPricebookId();
            PricebookEntry pbeTemplate = new PricebookEntry(
                Pricebook2Id = standardPBId,
                Product2Id = prodTemplate.Id,
                UnitPrice = 100.00,
                IsActive = true
            );
            PricebookEntry pbeVariant = new PricebookEntry(
                Pricebook2Id = standardPBId,
                Product2Id = prodVariant.Id,
                UnitPrice = 100.00,
                IsActive = true
            );
            insert new List<PricebookEntry>{pbeTemplate, pbeVariant};

            // Order
            Order ord = new Order(
                AccountId = acc.Id,
                Status = 'Draft',
                Pricebook2Id = standardPBId,
                Description = 'Test Order',
                EffectiveDate = Date.today(),
                Ratio__c = '1:2',
                Sizes__c = 'Large'
            );
            insert ord;
			
            // OrderItem
            OrderItem oi = new OrderItem(
                OrderId = ord.Id,
                Quantity = 1,
                UnitPrice = 100,
                Product2Id = prodVariant.Id,
                Description = 'OrderItem Description',
                PricebookEntryId = pbeVariant.Id
            );
            insert oi;
ord.Status='Activated';
            update ord;
            // Quote
            Quote q = new Quote(
                Name = 'Test Quote',
                OrderId__c = ord.Id,
                Status = 'Dispatch',
                Description = 'Quote Description',
                Ratio__c = '1:2',
                Pricebook2Id = standardPBId
            );
            insert q;

            // QuoteLineItem
            QuoteLineItem qli = new QuoteLineItem(
                QuoteId = q.Id,
                Quantity = 1,
                UnitPrice = 100,
                Product2Id = prodVariant.Id,
                PricebookEntryId = pbeVariant.Id
            );
            insert qli;
        }
    }

    @isTest
    static void testGetOrderSummaryData() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        User u = [SELECT Id FROM User WHERE Email = 'testuser@example.com' LIMIT 1];

        System.runAs(u) {
            Date startDate = Date.today();
            Date endDate = Date.today().addDays(1);

            Test.startTest();
            List<QuoteController.OrderWrapper> result = QuoteController.getOrderSummaryData(startDate, endDate);
            Test.stopTest();

            System.assertNotEquals(0, result.size(), 'OrderWrapper list should not be empty');

            QuoteController.OrderWrapper ow = result[0];

            System.assertEquals('Test Order', ow.orderDescription, 'Order description should match');
            System.assertEquals(1, ow.invoiceCount, 'There should be one invoice quote');
            System.assertEquals(1, ow.orderItems.size(), 'There should be one order item');
            System.assertEquals(1, ow.quotes.size(), 'There should be one quote');
        }
    }
}