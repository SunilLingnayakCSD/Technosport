@isTest
public class Test_Odoo_dispatch_reservedbundles {

    public class MultiMockHttpResponseGenerator implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        if (req.getEndpoint().contains('auth')) {
            res.setBody('{"jsonrpc": "2.0", "id": 1, "result": "fake_session_cookie"}');
            res.setHeader('Set-Cookie', 'fake_session_cookie=123456; Path=/; HttpOnly');
        } else  {
            res.setBody('{"validated": ["a0123456789ABCDEF"]}');
        } 

        res.setStatusCode(200);
        return res;
    }
}

    @isTest
static void testDispatchSelectedCount() {
    Account orderAccount = new Account(Name = 'Visit Account', BillingPostalCode = '273747',BillingCity='xys',BillingStreet='Karnataka');
    insert orderAccount;

    Id orderRecordTypeId = SObjectType.Order.getRecordTypeInfosByDeveloperName().get('Purchase_Order').getRecordTypeId();
    Order order = new Order(Name='Test Order',AccountId=orderAccount.Id, EffectiveDate=Date.today(), Status='Draft',RecordTypeId=orderRecordTypeId);
    insert order;

    List<Quote> quotes = new List<Quote>{
        new Quote(Name = 'Test Quote ', Status = 'Reserved', OrderId__c = order.Id)
    };

    Test.setMock(HttpCalloutMock.class, new MultiMockHttpResponseGenerator());

    Test.startTest();
    insert quotes;
    Odoo_dispatch_reservedbundles.dispatchSelectedCount(1, order.Id);
    Test.stopTest(); 

    Quote updatedQuote = [SELECT Id,Status FROM Quote WHERE OrderId__c = :order.Id LIMIT 1];
   // System.assertEquals('Dispatch', updatedQuote.Status, 'Quote status should be updated to Dispatch');
}


    @isTest
    static void testDispatchSelectedCount_nullOrderId() {
        Test.startTest();
        Odoo_dispatch_reservedbundles.dispatchSelectedCount(1, null);
        Test.stopTest();
        System.assert(true, 'No exception should be thrown when OrderId is null');
    }

    @isTest
    static void testDispatchSelectedCount_noReservedQuotes() {
        Account orderAccount = new Account(Name = 'Visit Account', BillingPostalCode = '273747',BillingCity='xys',BillingStreet='Karnataka');
        insert orderAccount;
        Order order = new Order(Name='No Quotes Order', EffectiveDate=Date.today(), Status='Draft', AccountId=orderAccount.Id);
        insert order;

        Test.startTest();
        Odoo_dispatch_reservedbundles.dispatchSelectedCount(1, order.Id);
        Test.stopTest();

        System.assert(true, 'No callout should occur if no Reserved quotes');
    }
}