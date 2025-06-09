@RestResource(urlMapping='/odoo/createsaleorder/*')
global class Odoo_SaleOrder_Creation_Into_Salesforce {
    
    @HttpPost()
    global static void createSalesOrder(){
        
        RestRequest request = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            String requestBody = request.requestBody.toString();
            System.debug('Data receiving from Odoo to Salesforce: ' + requestBody);
            OrderWrapper ordWrp = (OrderWrapper) JSON.deserialize(requestBody, OrderWrapper.class);
            System.debug('Order Wrapper: ' + JSON.serializePretty(ordWrp));
            if(ordWrp != null){
                Id priceBookId = getPriceBookId();
                System.debug('****priceBookId'+priceBookId);
                Account account = getAccount(ordWrp.partnerId);
                System.debug('*****account'+account);
                Map<String,String> productCodeMap = getProductCodeMap();
                Map<String,String> priceBookEntryIdMap = getPriceBookEntryIdMap(priceBookId);
                System.debug('*********productCodeMap'+productCodeMap);
                Order order = new Order();
                order.AccountId = account.Id;
                order.EffectiveDate = ordWrp.orderStartDate !=null ?Date.valueOf(ordWrp.orderStartDate):null;
                order.Status = 'Draft';
                order.Pricebook2Id = priceBookId;
                order.Order_Source__c = 'Odoo';
                order.Bundle_Quantity__c= ordWrp.bundleQuantity !=null?ordWrp.bundleQuantity:0;
                order.Ratio__c = ordWrp.ratio !=null ?ordWrp.ratio:'';
                order.Sizes__c=ordWrp.sizes !=null ?ordWrp.sizes:'';
                try{
                    insert order;
                    System.debug('*****Order Created'+order.Id);
                }catch(DmlException e){
                    System.debug(e);
                    RestContext.response.statusCode=500;
                    RestContext.response.responseBody = Blob.valueOf('Error Occured While Creating Order'+e.getMessage());
                }
                if(ordWrp.orderLineItems.size() > 0){
                    List<OrderItem> orderItems = getOrderItems(ordWrp.orderLineItems,productCodeMap,order.Id,priceBookEntryIdMap);
                    System.debug('*******orderItems'+orderItems);
                    if(orderItems.size() > 0 || !orderItems.isEmpty()){
                        insert orderItems;
                        System.debug('****orderItems Inserted'+orderItems.size());
                    }
                }
                if(ordWrp.quotes.size() > 0){
                    // List<Quote> quotes = getQuotes(ordWrp.quotes,priceBookId,order.Id,account.Id);
                    // List<QuoteLineItem> quoteLineItems = getQuoteLineItems(ordWrp.quotes.quoteLineItems,productCodeMap,priceBookEntryIdMap);
                    Map<String,String> resp= insertQuotesWithLineItems(ordWrp.quotes,priceBookId,order.Id,account.Id,productCodeMap,priceBookEntryIdMap);
                    Map<String,Object> response=new Map<String,Object>();
                    response.put('message','Created Successfully ');
                    response.put('status','Success');
                    response.put('result',new List<Object>{resp});
                    RestContext.response.statusCode=200;
                    RestContext.response.responseBody = Blob.valueOf(JSON.serialize(response));
                }
                
                
            }
        }catch(Exception e){
            RestContext.response.statusCode=500;
            RestContext.response.responseBody = Blob.valueOf('Error Occured '+e.getMessage());
        }
    }
    

    private static Map<String,String> insertQuotesWithLineItems(List<OrderWrapper.QuoteWrapper> quoteWrappers, 
                                              String pricebookId, 
                                              String orderId, 
                                              String accountId,
                                              Map<String, String> productCodeMap, 
                                              Map<String, String> priceBookEntryIdMap) {
    
    List<Quote> quotesToInsert = new List<Quote>();
    Map<String,String> quoteIdMap = new Map<String,String>();
    Map<String, List<OrderWrapper.QuoteLineItem>> quoteLineItemsMap = new Map<String, List<OrderWrapper.QuoteLineItem>>();
    
    for (OrderWrapper.QuoteWrapper qw : quoteWrappers) {
        Quote q = new Quote();
        
        q.Name = qw.quoteName;
        q.Order_Source__c = 'Odoo';
        q.Odoo_QuoteId__c = qw.odooQuoteId != null ? qw.odooQuoteId : '';
        q.OrderId__c = orderId;
        q.Pricebook2Id = pricebookId;
        q.Delivery_Date__c = qw.deliveryDate != null ? DateTime.valueOf(qw.deliveryDate) : null;
        q.QuoteAccountId = accountId;
        q.Status = 'Draft';

        quotesToInsert.add(q);

        Integer index = quotesToInsert.size() - 1;
        quoteLineItemsMap.put(String.valueOf(index), qw.quoteLineItems);
    }

    insert quotesToInsert;

       
    List<QuoteLineItem> quoteLineItemsToInsert = new List<QuoteLineItem>();

    for (Integer i = 0; i < quotesToInsert.size(); i++) {
        Quote insertedQuote = quotesToInsert[i];
        List<OrderWrapper.QuoteLineItem> qlis = quoteLineItemsMap.get(String.valueOf(i));

        if (qlis != null) {
            for (OrderWrapper.QuoteLineItem qli : qlis) {
                QuoteLineItem qliRec = new QuoteLineItem();
                qliRec.QuoteId = insertedQuote.Id;
                qliRec.Product_Type__c = qli.productType != null ? qli.productType : '';
                qliRec.PricebookEntryId = priceBookEntryIdMap.get(qli.productId);
                qliRec.Quantity = qli.quantity != null ? qli.quantity : 0;
                qliRec.UnitPrice = qli.unitPrice != null ? qli.unitPrice : 0;
                qliRec.Product2Id = productCodeMap.get(qli.productId);
                quoteLineItemsToInsert.add(qliRec);
            }
        }
    }

    insert quoteLineItemsToInsert;
    if(!quotesToInsert.isEmpty()){
        for (Quote q : quotesToInsert) {
            quoteIdMap.put(q.Odoo_QuoteId__c,q.Id);
        }
        return quoteIdMap;
    }
    return null;
}
private static DateTime parseOdooDateTime(String input) {
    if (String.isBlank(input)) return null;

    try {
        
        input = input.replace(',', '').replace('am', 'AM').replace('pm', 'PM').trim();

        List<String> parts = input.split(' ');
        if (parts.size() < 2) return null;

        Date datePart = Date.valueOf(parts[0]);
        String timePart = parts[1] + (parts.size() > 2 ? ' ' + parts[2] : ''); 

    
        DateTime dummyDT = DateTime.parse('1970-01-01 ' + timePart);
        Integer hour = dummyDT.hour();
        Integer minute = dummyDT.minute();
        Integer second = 0;

        return DateTime.newInstance(
            datePart.year(),
            datePart.month(),
            datePart.day(),
            hour,
            minute,
            second
        );
    } catch (Exception e) {
        System.debug('Error parsing date/time: ' + e.getMessage());
        return null;
    }
}


        private static Id getPriceBookId(){
            List<PriceBook2> priceBookList = [SELECT Id, Name, IsActive FROM PriceBook2 WHERE Name = 'Standard Price Book' AND IsActive = True];
            if(!priceBookList.isEmpty()){
                return priceBookList[0].Id;
            }else{
                return null;
            }
        }
        private static Account getAccount(String partnerId){
            List<Account> accountList = [SELECT Id, Name,External_Id__c FROM Account WHERE External_Id__c=:partnerId ];
            if(!accountList.isEmpty()){
                return accountList[0];
            }else{
                return null;
            }
        }
        private static Map<String,String> getProductCodeMap() {
            List<Product2> products = [
            SELECT Id, Name, Product_Template__c, Variant_ExternalId__c
            FROM Product2  
            WHERE Product_Template__c != null 
            AND Product_Type1__c = 'Product Variant' 
            AND Variant_ExternalId__c != null
        ];
            
            Map<String,String> productCodeMap = new Map<String,String>();
            for(Product2 p : products){
                productCodeMap.put(p.Variant_ExternalId__c, p.Id);
            }
            return productCodeMap;
        }
        private static Map<String,String> getPriceBookEntryIdMap(String priceBookId){
            Map<String,String> priceBookEntryMap = new Map<String,String>();
            List<PriceBookEntry> priceBookEntryList = [
           
            SELECT Id, Name, Pricebook2Id, Product2.Variant_ExternalId__c From PriceBookEntry  where Product2.Variant_ExternalId__c !=null AND Pricebook2Id=:priceBookId];
            if(!priceBookEntryList.isEmpty()){
                for(PriceBookEntry pbe:priceBookEntryList){
                    priceBookEntryMap.put(pbe.Product2.Variant_ExternalId__c, pbe.Id);
                }
            }
            return priceBookEntryMap;
        }
        private static List<OrderItem> getOrderItems(List<OrderWrapper.OrderLineItem> ordWrp,Map<String,String> productCodeMap,String orderId,Map<String,String> priceBookEntryIdMap){
            
            List<OrderItem> orderItems = new List<OrderItem>();
            if(ordWrp != null && ordWrp.size() > 0){
                for(OrderWrapper.OrderLineItem ordItemWrp :ordWrp){
                    OrderItem orderItem = new OrderItem();
                    orderItem.Quantity = ordItemWrp.quantity !=null?ordItemWrp.quantity:0;
                    orderItem.UnitPrice = ordItemWrp.unitPrice !=null ? ordItemWrp.unitPrice : 0;
                    orderItem.Product_Type__c = ordItemWrp.productType !=null?ordItemWrp.productType:'';
                    orderItem.Product2Id = productCodeMap.get(ordItemWrp.productId) !=null?  productCodeMap.get(ordItemWrp.productId):'';
                    orderItem.Colors__c=ordItemWrp.color !=null? ordItemWrp.color:'';
                    orderItem.OrderId = orderId;
                    orderItem.PricebookEntryId=priceBookEntryIdMap !=null ?priceBookEntryIdMap.get(ordItemWrp.productId) : '';
                    orderItems.add(orderItem);
                }
            }
            
            return orderItems;
            
        }
    }