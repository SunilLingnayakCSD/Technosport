@RestResource(urlMapping='/odoo/invoicedetails/LineItems/*')
global without sharing class Odoo_Invoice_details {
    
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
        public invoicePdfobject invoicePdf;
        public List<InvoiceLineItemWrapper>  invoice_line_items;
        public String delivery_address;
        public String remarks;
        public Decimal num_of_bundle;
    }
    
    global class invoicePdfobject {
        public String base64;
        public String fileName;
    }
    global class InvoiceLineItemWrapper {
        public String journalId;
        public String invoiceLineId;
        public String moveId;
        public String name;
        public Decimal priceUnit;
        public String productId;
        public Decimal quantity;
        
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
                    invoice.Name = payload.name !=null ?payload.name:'';
                    invoice.Transporter_Name__c = payload.local_transporter !=null ? payload.local_transporter:'';
                    invoice.LR_Date__c = payload.lr_date !=null?payload.lr_date:null;
                    invoice.LR_No__c = payload.lr_no != null ?payload.lr_no:'';
                    invoice.Invoice_Id__c = String.valueOf(payload.id) !=null ?String.valueOf(payload.id):String.valueOf('');
                    invoice.No_of_bundle__c=payload.num_of_bundle !=null ?payload.num_of_bundle:0;
                    invoice.Remarks__c=payload.remarks !=null ? payload.remarks:'';
                    
                    if (payload.partner_id != null) {
                        String partnerExternalId = payload.partner_id;
                        System.debug('partnerExternalId: ' + partnerExternalId);
                        
                        try {
                            List<Account> accountRecords= [SELECT Id, Name, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry,External_Id__c
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
                    invoice.Due_Date__c = payload.invoice_date_due !=null ?payload.invoice_date_due:null;
                    invoice.Invoice_Date__c = payload.invoice_date !=null ?payload.invoice_date:null;
                    invoice.Delivery_Address__c = payload.delivery_address !=null ?payload.delivery_address:'';
                    Quote attachedQuote;
                 
                    if (payload.salesforce_id != 'false') {
                        try {
                            attachedQuote = [SELECT Id,OrderId__c,Status FROM Quote WHERE Id = :payload.salesforce_id LIMIT 1];
                            
                            System.debug('attachedQuote: ' + attachedQuote);
                            if(attachedQuote !=null){
                                attachedQuote.status='Invoice';
                            }
                           
                            if (attachedQuote != null) {
                                invoice.Quote__c = payload.salesforce_id;
                            }
                        } catch (QueryException qe) {
                            System.debug('Error querying Salesforce Quote: ' + qe.getMessage());
                            throw new CustomException('Error querying Salesforce Quote with ID: ' + payload.salesforce_id);
                        }
                    }
                    insert invoice;
                    
                    String productId;
                    Map<String, Id> productMap = new Map<String, Id>();
                    for (Product2 p : [
                        SELECT Id, Variant_ExternalId__c 
                        FROM Product2 
                        WHERE Variant_ExternalId__c !=null
                    ]) {
                        productMap.put(p.Variant_ExternalId__c, p.Id);
                    }
                    if (payload.invoice_line_items != null && !payload.invoice_line_items.isEmpty()) {
                        List<Invoice_Line_Item__c> lineItemsToInsert = new List<Invoice_Line_Item__c>();
                        for (InvoiceLineItemWrapper lineItem : payload.invoice_line_items) {
                            Invoice_Line_Item__c item = new Invoice_Line_Item__c();
                            item.Invoice__c = invoice.Id;
                            item.JournalId__c = lineItem.journalId;
                            item.ExternalId__c = lineItem.invoiceLineId;
                            item.MoveId__c = lineItem.moveId;
                            item.Name = lineItem.name;
                            item.Unit_Price__c = lineItem.priceUnit;
                            item.Product__c = productMap.get(lineItem.productId);
                            item.Quantity__c = lineItem.quantity;
                            
                            lineItemsToInsert.add(item);
                        }
                        
                        if (!lineItemsToInsert.isEmpty()) {
                            insert lineItemsToInsert;
                        }
                    }
                    
                    if(invoice.Id !=null && payload.invoicePdf !=null){
                        
                        ContentVersion file = new ContentVersion();
                        file.VersionData = EncodingUtil.base64Decode(payload.invoicePdf.base64);
                        file.Title =  payload.invoicePdf.fileName.contains('.') ?
                            payload.invoicePdf.fileName.substring(0, payload.invoicePdf.fileName.lastIndexOf('.')) :
                            payload.invoicePdf.fileName;
                        
                        file.ContentLocation = 'S';
                        
                        file.PathOnClient =  payload.invoicePdf.fileName;
                        
                        file.Origin = 'H';
                        insert file;
                        ContentVersion insertedCV = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :file.Id LIMIT 1];
                        
                        ContentDocumentLink link = new ContentDocumentLink();
                        link.ContentDocumentId = insertedCV.ContentDocumentId;
                        link.LinkedEntityId = invoice.Id;
                        link.ShareType = 'V';
                        link.Visibility = 'AllUsers';
                        insert link;
                        
                    }
                    
                    if( invoice.id != null && attachedQuote!=null){
                        // update o;
                        update attachedQuote;
                    }
                    
                    RestContext.response.statusCode = 200;
                    RestContext.response.responseBody = Blob.valueOf('Invoice record created successfully'+invoice.Id);
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