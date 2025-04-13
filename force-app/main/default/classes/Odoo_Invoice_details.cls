@RestResource(urlMapping='/odoo/invoicedetail/*')
global class Odoo_Invoice_details {

    global class WebhookPayload {
        public String name;
        public String local_transporter;
        public Date lr_date;
        public String lr_no;
        public Integer id;
        public String partner_id;
        public Date invoice_date_due;
        public Date invoice_date;
        public String partner_shipping_id;
        public String journal_id;
        public String salesforce_id;
        public Decimal amount_paid;
        public String amount_total_words;
        public String ref;
        public Double amount_residual;

    }

    @HttpPost
    global static void handleWebhook() {
        try {
            RestRequest req = RestContext.request;
            String requestBody = req.requestBody.toString();
            
            System.debug('Odoo Webhook Request Body: ' + requestBody);
            
            WebhookPayload payload = (WebhookPayload)JSON.deserialize(requestBody, WebhookPayload.class);
            System.debug('Payload: ' + JSON.serializePretty(payload));
           
            if (payload != null && payload.invoice_date_due == null) {
                throw new CustomException('Missing required field: invoice_date_due');
            }

            if (payload != null) {
                Invoice__c invoice = new Invoice__c();

                try {
                    if (payload.name != null) {
                        invoice.Name = payload.name;
                    }

                    if (payload.local_transporter != null) {
                        invoice.Transporter_Name__c = payload.local_transporter;
                    }

                    if (payload.lr_date != null) {
                        invoice.LR_Date__c = payload.lr_date;
                    }

                    if (payload.lr_no != null) {
                        invoice.LR_No__c = payload.lr_no;
                    }

                    if (payload.id != null) {
                        invoice.Invoice_Id__c = String.valueOf(payload.id); 
                    }

                    List<Account> accountRecords;
                    
                    if (payload.partner_id != null) {
                        String partnerExternalId = payload.partner_id;
                        System.debug('partnerExternalId: ' + partnerExternalId);
                        
                        try {
                            accountRecords = [SELECT Id, Name, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry,External_Id__c
                                              FROM Account 
                                              WHERE External_Id__c = :partnerExternalId 
                                              LIMIT 1];
                            System.debug('Account found------------->' + accountRecords);

                            if (!accountRecords.isEmpty()) {
                                Account accountRecord = accountRecords[0];
                                invoice.Account__c = accountRecord.Id; 
                                invoice.Shipping_Street_c__c = accountRecord.ShippingStreet;
                                invoice.Shipping_City_c__c = accountRecord.ShippingCity;
                                invoice.Shipping_State__c = accountRecord.ShippingState;
                                invoice.Shipping_Postal_Code__c = accountRecord.ShippingPostalCode;
                                invoice.Shipping_Country__c = accountRecord.ShippingCountry;
                            } else {
                                System.debug('No Account found for External ID: ' + partnerExternalId);
                            }
                        } catch (Exception e) {
                            System.debug('Error fetching Account record: ' + e.getMessage());
                            throw new CustomException('Error fetching Account record for External ID: ' + partnerExternalId);
                        }
                    }

                    if (payload.invoice_date_due != null) {
                        invoice.Due_Date__c = payload.invoice_date_due;
                    }

                    if (payload.invoice_date != null) {
                        invoice.Invoice_Date__c = payload.invoice_date;
                    }

                    if (payload.partner_shipping_id != null) {
                        invoice.Delivery_Address__c = payload.partner_shipping_id;
                    }
                    

                    // if (payload.journal_id != null) {
                    //     invoice.Invoice_Id__c = payload.journal_id; 
                    // }
                    Quote attachedQuote;
                    Order o;
                    if (payload.salesforce_id != null) {
                        try {
                             attachedQuote = [SELECT Id,OrderId__c,Status FROM Quote WHERE Id = :payload.salesforce_id LIMIT 1];
                            
                            System.debug('attachedQuote: ' + attachedQuote);
                            if(attachedQuote !=null){
                                attachedQuote.status='Invoice';
                            }
                           o=[Select Id,Status From Order WHERE Id=:attachedQuote.OrderId__c];
                            if(o != null){
                                o.Status='Invoice';
                               
                            }
                            if (attachedQuote != null) {
                                invoice.Quote__c = payload.salesforce_id;
                            }
                        } catch (QueryException qe) {
                            System.debug('Error querying Salesforce Quote: ' + qe.getMessage());
                            throw new CustomException('Error querying Salesforce Quote with ID: ' + payload.salesforce_id);
                        }
                    }

                    if (payload.amount_total_words != null) {
                        invoice.Amount_in_Words__c = payload.amount_total_words;
                    }

                    invoice.Amount__c = payload.amount_paid != null ? payload.amount_paid : 0;
                    invoice.Reference__c = payload.ref != null ? payload.ref : '';

                    if (payload.amount_residual != null) {
                        invoice.Residual_Amount__c = payload.amount_residual;
                    }

                    System.debug('Mapped Invoice: ' + JSON.serializePretty(invoice));

                   
                    if (invoice.Name == null) {
                        throw new DmlException('Invoice Name cannot be null');
                    }
                    
                    insert invoice;
                    if(o!=null && invoice.id != null){
                         update o;
                         update attachedQuote;
                    }   

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