public class OdooIntegration {
    private static final String ODOO_API_URL;
    private static final String ODOO_AUTH_URL;
    private static final String ODOO_DB;
    private static final String ODOO_USERNAME;
    private static final String ODOO_PASSWORD;
    public static  String sessionId;

    static {
        OdooSettings__mdt odooSettings = [SELECT MasterLabel, ODOO_API_URL__c, ODOO_AUTH_URL__c, ODOO_DB__c, ODOO_USERNAME__c, ODOO_PASSWORD__c
                                          FROM OdooSettings__mdt 
                                          WHERE MasterLabel = 'OdooCrdentials' LIMIT 1];
        System.debug('custom Metadata------->'+odooSettings);
        if (odooSettings != null) {
            ODOO_API_URL = odooSettings.ODOO_API_URL__c;
            ODOO_AUTH_URL = odooSettings.ODOO_AUTH_URL__c;
            ODOO_DB = odooSettings.ODOO_DB__c;
            ODOO_USERNAME = odooSettings.ODOO_USERNAME__c;
            ODOO_PASSWORD = odooSettings.ODOO_PASSWORD__c;
        } else {
            throw new CustomException('No Odoo Credentials found in OdooSettings__mdt.');
        }
       
            String sessionCookie = authenticate();

            if (sessionCookie != null) {
                sessionId=sessionCookie;
            }
    }

    public static String authenticate() {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(ODOO_AUTH_URL);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(10000);

            String authBody = JSON.serialize(new Map<String, Object> {
                'jsonrpc' => '2.0',
                'id' => 1,
                'method' => 'call',
                'params' => new Map<String, Object> {
                    'db' => ODOO_DB,
                    'login' => ODOO_USERNAME,
                    'password' => ODOO_PASSWORD
                }
            });

            req.setBody(authBody);
            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                System.debug('*****************'+res.getBody());
                String sessionCookie = res.getHeader('Set-Cookie');
                if (sessionCookie != null) {
                    System.debug('*******authenticated Successfully!');
                    return sessionCookie;
                } else {
                    throw new CalloutException('Session cookie not found in response.');
                }
            } else {
                throw new CalloutException('Authentication failed with status: ' + res.getStatus() + ', Body: ' + res.getBody());
            }
        } catch (Exception e) {
            throw new CalloutException('Error during authentication: ' + e.getMessage(), e);
        }
    }

    public static String createSalesOrder(String sessionCookie, Id quoteId) {
        try {
            Quote quote = [
                SELECT Id, Name, QuoteAccountId,QuoteAccount.External_Id__c, Delivery_Date__c, QuoteNumber, TotalPrice, BillingAddress, ShippingAddress,ExpirationDate,CreatedDate,isNextAvailbleProductQuote__c
                FROM Quote
                WHERE Id = :quoteId
                LIMIT 1
            ];
            System.debug('*********quote*****'+quote);
            if (quote == null) {
                throw new CustomException('Quote with ID ' + quoteId + ' not found.');
            }

            List<QuoteLineItem> lineItems = [
                SELECT Id, Product2Id, Product2.Name,Product2.Variant_ExternalId__c,Product2.Product_Template__r.isFutureProduct__c,Product2.Product_Template__r.Product_Launch_Date__c, Quantity, UnitPrice, Description
                FROM QuoteLineItem
                WHERE QuoteId = :quoteId
            ];
            if(lineItems.isEmpty()){
                throw new CustomException('Quote lineItems are Empty. ');
            }
            Date createdDate;
            DateTime createdDateTime = quote.CreatedDate;
            List<Object> orderLines = new List<Object>();
            for (QuoteLineItem item : lineItems) {
                orderLines.add(new List<Object> {
                    0, 0, new Map<String, Object> {
                         'product_id'  =>Integer.valueOf(item.Product2.Variant_ExternalId__c),
                        'product_uom_qty' => item.Quantity,
                        'name' => item.Product2.name+'-'+item.Description            
                    }
                });
                createdDate =item.Product2.Product_Template__r.isFutureProduct__c==true?item.Product2.Product_Template__r.Product_Launch_Date__c: createdDateTime.date();
            }
            System.debug('orderLines----'+orderLines);
			System.debug('order date---->'+quote.CreatedDate);
            		 
                
            DateTime expirationdatetime=quote.ExpirationDate != null ?quote.ExpirationDate:null  ;
             Date expireDate;
            if(expirationdatetime != null){
                expireDate =expirationdatetime.date();
            }
          
            
            System.debug('formatted Date'+createdDate);
            Map<String, Object> salesOrderPayload = new Map<String, Object> {
                'jsonrpc' => '2.0',
                'id' => 2,
                'method' => 'call',
                'params' => new Map<String, Object> {
                    'model' => 'sale.order',
                    'method' => 'create',
                    'args' => new List<Object> {
                        new Map<String, Object> {
                            'partner_id' => Integer.valueOf(quote.QuoteAccount.External_Id__c), 
                            'partner_invoice_id' => Integer.valueOf(quote.QuoteAccount.External_Id__c),
                            'partner_shipping_id' => Integer.valueOf(quote.QuoteAccount.External_Id__c),
                            'salesforce_id' => quote.Id,
                            'order_line' => orderLines,
                            'validity_date'=>expireDate !=null ?expireDate:null,
                            'date_order'=>createdDate,
                            'upcoming'=>Boolean.valueOf(quote.isNextAvailbleProductQuote__c)
                            //  'pricelist_id'=>17
                        }
                    },
                    'kwargs' => new Map<String, Object>()
                }
            };
                

            HttpRequest req = new HttpRequest();
            req.setEndpoint(ODOO_API_URL);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Cookie', sessionCookie);
            req.setBody(JSON.serialize(salesOrderPayload));

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                if (response.containsKey('result')) {
                    System.debug('***********************'+response.get('result'));
                    return 'Sales Order Created in Odoo, ID: ' + response.get('result');
                } else {
                    throw new CalloutException('Error response from Odoo: ' + JSON.serializePretty(response));
                }
            } else {
                throw new CalloutException('Error creating Sales Order: ' + res.getStatus() + ', Body: ' + res.getBody());
            }
        } catch (Exception e) {
            throw new CalloutException('Error during Sales Order creation: ' + e.getMessage(), e);
        }
    }

    @Future(callout = true)
    public static void sendQuoteToOdoo(List<Id> quoteIds) {
        if (quoteIds == null || quoteIds.isEmpty()) {
            throw new IllegalArgumentException('Quote IDs list cannot be null or empty.');
        }

        try {
            //String sessionCookie = authenticate();
            for (Id quoteId : quoteIds) {
                String response = createSalesOrder(sessionId, quoteId);
                System.debug('Response from Odoo for Quote ' + quoteId + ': ' + response);
            }
        } catch (Exception e) {
            System.debug('Error in sendQuoteToOdoo: ' + e.getMessage());
        }
    }
     public class CustomException extends Exception {}
}