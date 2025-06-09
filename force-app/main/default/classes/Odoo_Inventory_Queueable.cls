global class Odoo_Inventory_Queueable implements Queueable, Database.AllowsCallouts {

    public static String baseUrl ;
    public static Decimal uid;
    public static String ODOO_DB;
    public static String objectModule = 'product.product';
    public static String searchMethod = 'search_read';
    public static String ODOO_PASSWORD;
    public static String sessionCookie;

    static {
        OdooSettings__mdt odooSettings = [SELECT MasterLabel, ODOO_INV_URL__c, ODOO_UID__c, ODOO_DB__c, ODOO_PASSWORD__c
                                          FROM OdooSettings__mdt 
                                          WHERE MasterLabel = 'OdooCrdentials' LIMIT 1];
        System.debug('custom Metadata------->' + odooSettings);
        if (odooSettings != null) {
            baseUrl = odooSettings.ODOO_INV_URL__c;
            uid = odooSettings.ODOO_UID__c;
            ODOO_DB = odooSettings.ODOO_DB__c;
            ODOO_PASSWORD = odooSettings.ODOO_PASSWORD__c;
          
        } else {
            throw new AuraHandledException('No Odoo Credentials found in OdooSettings__mdt.');
        }
    }

    global void execute(QueueableContext context) {
        sessionCookie = OdooIntegration.authenticate();
        List<Product2> productList = [SELECT Id, Variant_ExternalId__c FROM Product2 WHERE Variant_ExternalId__c != NULL];
        System.debug('Product2 List: ' + productList);

        List<Integer> productIds = new List<Integer>();
        for (Product2 p : productList) {
            productIds.add(Integer.valueOf(p.Variant_ExternalId__c));
        }

        Map<String, Object> requestBody = new Map<String, Object>();
        requestBody.put('jsonrpc', '2.0');
        requestBody.put('method', 'call');

        Map<String, Object> params = new Map<String, Object>();
        params.put('service', 'object');
        params.put('method', 'execute_kw');

        List<Object> args = new List<Object>{
            ODOO_DB,  
            uid,   
            ODOO_PASSWORD, 
            objectModule,  
            searchMethod, 
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
        req.setEndpoint(baseUrl);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Cookie', sessionCookie);  
        req.setBody(jsonBody);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            System.debug('Response: ' + res.getBody());
            String respBody = res.getBody();
            List<Inventory__c> inventoryToInsert = parseInventoryDetails(respBody, productList);

            if (inventoryToInsert != null && !inventoryToInsert.isEmpty()) {
                upsert inventoryToInsert External_Id__c;
                System.debug('Upserted successfully: ' + inventoryToInsert);
            }
        } else {
            System.debug('Error: ' + res.getStatusCode() + ' - ' + res.getBody());
        }
    }

    private static List<Inventory__c> parseInventoryDetails(String responseBody, List<Product2> productList) {
        List<Inventory__c> inventoryToInsert = new List<Inventory__c>();

        try {
            Map<String, Object> resultData = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            List<Object> inventoryData = (List<Object>) resultData.get('result');
            System.debug('Inventory Data: ' + inventoryData);

            if (inventoryData != null) {
                Map<Integer, Product2> productMap = new Map<Integer, Product2>();

                for (Product2 p : productList) {
                    productMap.put(Integer.valueOf(p.Variant_ExternalId__c), p);
                }

                for (Object record : inventoryData) {
                    Map<String, Object> invRecord = (Map<String, Object>) record;
                    Integer productId = (Integer) invRecord.get('id');
                    Decimal qtyAvailable = (Decimal) invRecord.get('qty_available');
                    Decimal freeQty = (Decimal) invRecord.get('free_qty');

                    Product2 product = productMap.get(productId);

                    if (product != null) {
                        Inventory__c inventoryRecord = new Inventory__c();
                        inventoryRecord.Product__c = product.Id;
                        inventoryRecord.Available_Quantity__c = qtyAvailable;
                        inventoryRecord.Free_Quantity__c = freeQty;
                        inventoryRecord.External_Id__c = String.valueOf(productId);
                        inventoryToInsert.add(inventoryRecord);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error parsing inventory details: ' + e.getMessage());
        }

        return inventoryToInsert;
    }
}