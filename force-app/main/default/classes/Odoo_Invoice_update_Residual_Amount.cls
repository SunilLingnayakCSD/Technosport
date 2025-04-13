@RestResource(urlMapping='/odoo/invoiceupdate')
global without sharing class Odoo_Invoice_update_Residual_Amount {
   @httpPost()
    global static void updateResidualAmount(){
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;

        try{
            String requestBody = request.requestBody.toString();

            System.debug('Data receiving from Odoo to Salesforce: ' + requestBody);
            Map<String, Object>
            parsedData = (Map<String, Object>)JSON.deserializeUntyped(requestBody);
            System.debug('Parsed Data: ' + parsedData);
            
           if(parsedData.containsKey('id')){
            List<Invoice__c> invoicetoUpdate=new List<Invoice__c>();
            System.debug((Integer)parsedData.get('id')+'********************');
            Integer externalId=(Integer)parsedData.get('id');
            String convertedId=String.valueOf(externalId);

            System.debug(convertedId+'**********-');
                List<Invoice__c> invoiceList = [SELECT Id, Residual_Amount__c,Name FROM Invoice__c WHERE Invoice_Id__c = : convertedId];

                Decimal residual=parsedData.get('amount_residual') != null ?(Decimal)parsedData.get('amount_residual'):0;
                Decimal amountPaid=parsedData.get('amount_paid') != null ?(Decimal)parsedData.get('amount_paid'):0;
                for(Invoice__c invoice:invoiceList){
                    invoice.Amount__c=amountPaid;
                    invoice.Residual_Amount__c=residual;
                    invoicetoUpdate.add(invoice);
                }
               
                if(!invoicetoUpdate.isEmpty()){
                    try{
                update invoicetoUpdate;
                RestContext.response.statusCode = 200;
                RestContext.response.responseBody = Blob.valueOf('Webhook processed and Invoice record updated successfully');
                    }catch(Exception e){
                        System.debug('DML Error: ' + e.getMessage());
                RestContext.response.statusCode = 500;
                RestContext.response.responseBody = Blob.valueOf('DML Error: ' + e.getMessage());
                    }
                }
            
                
            
        
           }else{
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf('Webhook processed and Invoice record Not Found');
           }
           
        }catch(Exception e){
            System.debug('Exception: ' + e);
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf('Error processing webhook: ' + e.getMessage());
        }
    }

}