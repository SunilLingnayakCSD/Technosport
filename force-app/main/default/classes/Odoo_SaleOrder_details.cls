@RestResource(urlMapping='/odoo/saleorderdetail/*')
global class Odoo_SaleOrder_details {
global class WebhookPayload {
        public String name;
        public String state;
        public String salesforce_id;
          }

    @HttpPost()
    global static void handleWebhook() {
        try {
            RestRequest req = RestContext.request;
            String requestBody = req.requestBody.toString();
            
            System.debug('Odoo Webhook Request Body: ' + requestBody);
            
            WebhookPayload payload = (WebhookPayload)JSON.deserialize(requestBody, WebhookPayload.class);
            System.debug('Payload: ' + JSON.serializePretty(payload));

        // Validate the payload
            if (payload == null || payload.salesforce_id == null || payload.state == null) {
                throw new CustomException('Missing required fields: salesforce_id or state');
            }
                

            if (payload != null) {
               

                try {
                    Quote o=[Select Id,OrderId__c   From Quote Where Id=:payload.salesforce_id];
                     Order orde;
                /*if(o != null){
                     orde=[Select Id,Status From Order where Id=:o.OrderId__c ];
                }*/

                    if (o != null && payload.State != null ) {
                        
                        if(payload.State =='sale'){
                       o.Status = 'SalesOrder';
                        }
                    }

                   
                    update o;

                    RestContext.response.statusCode = 200;
                    RestContext.response.responseBody = Blob.valueOf('Webhook processed and Invoice record updated successfully');
                } catch (DmlException dmlEx) {
                    System.debug('DML Error: ' + dmlEx.getMessage());
                    RestContext.response.statusCode = 500;
                    RestContext.response.responseBody = Blob.valueOf('DML Error: ' + dmlEx.getMessage());
                } catch (Exception e) {
                    System.debug('General Error: ' + e.getMessage());
                    RestContext.response.statusCode = 500;
                    RestContext.response.responseBody = Blob.valueOf('Error processing webhook: ' + e.getMessage());
                }
            }
        } catch (Exception e) {
            System.debug('Error processing webhook: ' + e.getMessage());
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf('Error processing webhook: ' + e.getMessage());
        }
    }

    public class CustomException extends Exception {}
}