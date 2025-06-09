@RestResource(urlMapping='/odoo/webhook')
global with sharing class OdooWebhookHandler {

    
    @HttpPost
    global static void handleWebhook() {
        try {
           
            RestRequest req = RestContext.request;
            String requestBody = req.requestBody.toString();
            

            System.debug('Odoo Webhook Request Body: ' + requestBody);

            
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(requestBody);

            
            if (payload != null) {
                
                if (payload.containsKey('event')) {
                    String eventType = (String) payload.get('event');
                    System.debug('Event Type: ' + eventType);
                }
                if (payload.containsKey('data')) {
                    Map<String, Object> data = (Map<String, Object>) payload.get('data');
                    System.debug('Event Data: ' + JSON.serializePretty(data));
                }
            }
            
          
            RestResponse res = RestContext.response;
            res.statusCode = 200;
            res.responseBody = Blob.valueOf('Webhook processed successfully');
        } catch (Exception e) {
            System.debug('Error processing webhook: ' + e.getMessage());
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf('Error processing webhook');
        }
    }
}