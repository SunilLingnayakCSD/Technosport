public with sharing class Odoo_Inventory_helper {
    private static String baseUrl = 'https://technosport-staging-15695166.dev.odoo.com/jsonrpc'; 

    public static void getInventoryDetails() {
        //String endpoint = '/web/dataset/call_kw';
        String url = baseUrl ;
        
       String sessionCookie= OdooIntegration.authenticate();
        System.debug(sessionCookie);
       
        
        
       Map<String, Object> requestBody = new Map<String, Object>();
       requestBody.put('jsonrpc', '2.0');
       requestBody.put('method', 'call');
       
       Map<String, Object> params = new Map<String, Object>();
       params.put('service', 'object');
       params.put('method', 'execute_kw');
       
       List<Object> args = new List<Object>{
           'technosport-staging-15695166',  
           2,   
           'ADMIN', 
           'product.product',  
           'search_read', 
           new List<List<List<Object>>>{
            new List<List<Object>>{
                new List<Object>{'categ_id', 'in', new List<Integer>{95, 138}}  
            }
        },
           new Map<String, Object>{'fields' => new List<String>{'qty_available', 'free_qty'}}  
       };
       
       params.put('args', args);
       
       requestBody.put('params', params);
       
       String jsonBody = JSON.serialize(requestBody);
       
       HttpRequest req = new HttpRequest();
       req.setEndpoint(url);
       req.setMethod('POST');
       req.setHeader('Content-Type', 'application/json');
        req.setHeader('Cookie', sessionCookie);  // Uncomment if you need to add authentication cookie
       req.setBody(jsonBody);
       
       System.debug('Request Body: ' + jsonBody);
       
       Http http = new Http();
       HttpResponse res = http.send(req);
       
       if (res.getStatusCode() == 200) {
           System.debug('Response: ' + res.getBody());
           String respBody= res.getBody();
           parseInventoryDetails(respBody);
       } else {
           System.debug('Error: ' + res.getStatusCode() + ' - ' + res.getBody());
       }
       
    }

    
    private static void parseInventoryDetails(String responseBody) {
        
        try {
            Map<String,Object> resultData= (Map<String, Object>)JSON.deserializeUntyped(responseBody);
            System.debug(resultData);
            if(resultData!= null){
            List<Object> inventoryData = (List<Object>)resultData.get('result');
            if(inventoryData != null){
            for (Object record : inventoryData) {
                Map<String, Object> invRecord = (Map<String, Object>)record;
                Integer productId=(Integer)invRecord.get('id');
                Decimal qtyAvailable = (Decimal)invRecord.get('qty_available');
                Decimal freeQty = (Decimal)invRecord.get('free_qty');
                
                System.debug('Product Inventory - Qty Available: ' + qtyAvailable + ', Free Qty: ' + freeQty);
            }
        }else{
            System.debug('inventory data is null');
        }
        }
        } catch (Exception e) {
            System.debug('Error parsing inventory details: ' + e.getMessage());
        }
    }
}