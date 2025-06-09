@RestResource(urlMapping='/odoo/inventory/*')
global class Odoo_Inventory_items {
    global class InventoryWrapper {
        public String model;    
        public String name;    
        public Double avg_cost;    
        public String display_name;    
        public Decimal free_qty;    
        public Integer id;    
        public Decimal qty_available;    
        public Integer uom_id;
        public String categ_id;
    }

    @HttpPost()
    global static void getInventoryDetails() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        
        try {
            String requestBody = request.requestBody.toString();
            System.debug('Odoo Webhook Request Body: ' + requestBody);
            
            
            InventoryWrapper payload = (InventoryWrapper)JSON.deserialize(requestBody, InventoryWrapper.class);
            System.debug('Payload: ' + JSON.serializePretty(payload));

            if (payload == null || payload.id == null) {
                throw new CustomException('Missing required field: id in the request payload');
            }

            Product2 pro = [SELECT Id, Name, Product_External_ID__c FROM Product2 WHERE Product_External_ID__c = :String.valueOf(payload.id) LIMIT 1];
            
            if (pro == null) {
                throw new CustomException('No Product found for ExternalId: ' + payload.id);
            }

            Inventory__c inv = new Inventory__c();
            inv.Product__c = pro.Id;
            inv.Avg_Cost__c = payload.avg_cost != null ? payload.avg_cost : 0;
            inv.Free_Quantity__c = payload.free_qty != null ? payload.free_qty : 0;
            inv.Available_Quantity__c = payload.qty_available != null ? payload.qty_available : 0;
            inv.Display_Name__c = payload.display_name != null ? payload.display_name : '';
            inv.External_Id__c = String.valueOf(payload.id) != null ? String.valueOf(payload.id) : '';

            try {
                upsert inv External_Id__c;
            } catch (DmlException dmlEx) {
                throw new CustomException('DML Error while upserting Inventory: ' + dmlEx.getMessage());
            }

            response.statusCode = 200;
            response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
                'status' => 'Success',
                'message' => 'Inventory Items Created/Updated Successfully - ' + inv.Id,
                'Inventory Id' => inv.Id
            }));

        } catch (CustomException ce) {
            
            response.statusCode = 400;  
            response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
                'status' => 'Error',
                'message' => 'Custom Error: ' + ce.getMessage()
            }));
            System.debug('Custom Exception: ' + ce.getMessage());
        } catch (QueryException qe) {
           
            response.statusCode = 404;  
            response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
                'status' => 'Error',
                'message' => 'Query Error: ' + qe.getMessage()
            }));
            System.debug('Query Exception: ' + qe.getMessage());
        } catch (DmlException dmlEx) {
            
            response.statusCode = 500; 
            response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
                'status' => 'Error',
                'message' => 'DML Error: ' + dmlEx.getMessage()
            }));
            System.debug('DML Exception: ' + dmlEx.getMessage());
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