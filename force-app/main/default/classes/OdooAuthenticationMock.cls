// Create a mock class for HTTP callout
public class OdooAuthenticationMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        // Simulating a successful authentication response
        res.setStatusCode(200);
        res.setBody('{"jsonrpc": "2.0", "id": 1, "result": "session_cookie"}');
        res.setHeader('Set-Cookie', 'session_cookie=123456; Path=/; HttpOnly');
        return res;
    }
}