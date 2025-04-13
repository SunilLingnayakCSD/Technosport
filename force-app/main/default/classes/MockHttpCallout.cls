@isTest
global class MockHttpCallout implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        System.debug('Mock request received: ' + req.getEndpoint());

        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('{"success": true, "message": "Mock callout success"}');
        return res;
    }
}