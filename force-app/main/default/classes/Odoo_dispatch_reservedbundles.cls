public with sharing class Odoo_dispatch_reservedbundles {
    @AuraEnabled
    public static void dispatchSelectedCount(Integer Count,String OrderId){
        try {
            if(OrderId!=null){
                List<Quote> getReservedQuotes=[Select Id From Quote Where OrderId__c= :OrderId AND Status='Reserved' limit : Count];
                
                if(getReservedQuotes.size()>0){
                    Set<String> salesforceId=new Set<String>();
                    for(Quote q:getReservedQuotes){
                        salesforceId.add(q.Id);
                    }
                    if(salesforceId.size()>0){
                        
                        Map<String,Object> sendingBody=new Map<String,Object>();
                        sendingBody.put('salesforce_ids',salesforceId);
                        String JsonBody=JSON.Serialize(sendingBody);
                        calloutToOdooToDispatch(JsonBody);
                    }
                }
            }
        } catch (LimitException  e) {
            throw new LimitException(e.getMessage());
        }
    }
    @Future(callout=true)
    public static void calloutToOdooToDispatch(String JsonBody){
        try{
            OdooSettings__mdt odooSettings = [SELECT MasterLabel,DISPATCH_API__c,ODOO_PWD_KEY__c
                                          FROM OdooSettings__mdt 
                                          WHERE MasterLabel = 'OdooCrdentials' LIMIT 1];
            System.debug('custom Metadata------->'+odooSettings);
            String endpoint;
            String ODOO_PASSWORD;
            if (odooSettings != null) {
                endpoint = odooSettings.DISPATCH_API__c;
                ODOO_PASSWORD = odooSettings.ODOO_PWD_KEY__c;
            } else {
                throw new AuraHandledException('No Odoo Credentials found in OdooSettings__mdt.');
            }
            Http h=new Http();
            HttpRequest req=new HttpRequest();
            req.setEndPoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer '+ODOO_PASSWORD);
            req.setBody(JsonBody);
            System.debug('JsonBody====>'+JsonBody);
            System.debug('Request====>'+req);
            HttpResponse resp=h.send(req);
            System.debug(resp.getBody());
            
            if(resp.getStatusCode()==200){
                System.debug('Processed Successfuly');
                System.debug(resp.getBody());
                Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(resp.getBody());
                Object validatedObj = response.get('validated');
                
                if (validatedObj != null && validatedObj instanceof List<Object>) {
                    List<String> result = new List<String>();
                    for (Object o : (List<Object>)validatedObj) {
                        if (o != null) result.add((String)o);
                    }
                    
                    System.debug('result: ' + result);
                    
                    if (!result.isEmpty()) {
                        List<Quote> quotestoupdate = [SELECT Id, Status FROM Quote WHERE Id IN :result];
                        System.debug('quotestoupdate: ' + quotestoupdate);
                        
                        List<Quote> quoteNeedstoupdate = new List<Quote>();
                        for (Quote q : quotestoupdate) {
                            q.Status = 'Dispatch';
                            quoteNeedstoupdate.add(q);
                        }
                        
                        if (!quoteNeedstoupdate.isEmpty()) {
                            update quoteNeedstoupdate;
                        }
                    }
                }
                
            }else{
                System.debug('something went wrong');
                System.debug('Response: ' + resp.getBody());
            }
        }catch(Exception e){
            System.debug('error'+e.getMessage());
            throw new AuraHandledException(e.getMessage());
            
        }
        
    }
    
}