@RestResource(urlMapping='/odoo/invoicelinedetails1/*')
global without sharing class Odoo_Invoice_lineItems_Details {

    @HttpPost()
    global static void insertInvoiceFromOdooToSalesFroce(){
        
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        
        try {
            
            String requestBody = request.requestBody.toString();
            System.debug('Data receiving from Odoo to Salesforce: ' + requestBody);
            Map<String, Object> parsedData = (Map<String, Object>)JSON.deserializeUntyped(requestBody);
            System.debug('Parsed Data: ' + parsedData);
			System.debug(JSON.serializePretty(parsedData));
           
            String journalId = String.valueOf((Integer)parsedData.get('journal_id'));
            String model = (String) parsedData.get('_model');
            String actionname = (String) parsedData.get('_name');
            Date delivery_date = (Date) parsedData.get('delivery_date');
            String invoicelineId = String.valueOf((Integer)parsedData.get('id'));
            String moveId = String.valueOf((Integer)parsedData.get('move_id'));
            String Name = (String) parsedData.get('name');
            Decimal price_subtotal = (Decimal) parsedData.get('price_subtotal');
            Decimal price_unit = (Decimal) parsedData.get('price_unit');
            String product_id = String.valueOf((Integer) parsedData.get('product_id'));
            Integer quantity = Integer.valueOf(parsedData.get('quantity'));
             String productId;
            
            Product2 pro=[Select Id,Variant_ExternalId__c From Product2 Where Variant_ExternalId__c=:product_id];
            if(pro!=null){
                productId=pro.Id;
            }else{
                productId='';
            }
            // Invoice__c invoice = [SELECT Id, Invoice_Id__c FROM Invoice__c WHERE Invoice_Id__c = :String.valueOf(moveId) LIMIT 1];
            // if (invoice == null) {
            //     throw new CustomException('No Invoice found for Journal ID: ' + moveId);
            // }

            // System.debug('Invoice found: ' + invoice);

           
            InvoiceLineItem__c lineItems = new InvoiceLineItem__c();
            lineItems.MoveId__c = moveId;
            lineItems.Unit_Price__c = price_unit != null ? price_unit : 0;
            lineItems.Quantity__c = quantity != null ? quantity : 0;
            lineItems.ExternalId__c=invoicelineId;
            lineItems.Product__c=productId;

            try {
                upsert lineItems ExternalId__c;
                System.debug('Invoice Line Item created with ID: ' + lineItems.Id);
            } catch (DmlException dmlEx) {
                throw new CustomException('DML Error during insert: ' + dmlEx.getMessage());
            }

            response.statusCode = 200;
            response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
                'status' => 'Success',
                'message' => 'Line Items Created Successfully - ' + lineItems.Id,
                'lineItem Id' => lineItems.Id
            }));

      /*  } catch (CustomException ce) {
            
            response.statusCode = 400;  
            response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
                'status' => 'Error',
                'message' => 'Custom Error: ' + ce.getMessage()
            }));
            System.debug('Custom Exception: ' + ce.getMessage()); */

        } catch (QueryException qe) {
            
            response.statusCode = 404;  
            response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
                'status' => 'Error',
                'message' => 'Query Error: ' + qe.getMessage()
            }));
            System.debug('Query Exception: ' + qe.getMessage());

      /*  } catch (DmlException dmlEx) {
          
            response.statusCode = 500;  
            response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
                'status' => 'Error',
                'message' => 'DML Error: ' + dmlEx.getMessage()
            }));
            System.debug('DML Exception: ' + dmlEx.getMessage());*/

        } catch (Exception e) {
            
            response.statusCode = 500;  
            response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
                'status' => 'Error',
                'message' => 'General Error: ' + e.getMessage()
            }));
            System.debug('General Exception: ' + e.getMessage());
        }
    }

    public class CustomException extends Exception {}
}