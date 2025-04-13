public class CreateQuoteController {
    public static void createQuote(List<Order> orderData) {
        System.debug('**************InsideOrderCreate ' + orderData);
        Set<Id> orderIds = new Set<Id>();
        for (Order o : orderData) {
            orderIds.add(o.Id);
        }

        List<OrderItem> orderItemDetails = [SELECT Id, OrderId, Product2Id, PricebookEntryId, Quantity, UnitPrice, ListPrice, 
                                            S__c, M__c, L__c, XL__c, XXL__c, XXXL__c, Colors__c, Description, Product_Type__c 
                                            FROM OrderItem 
                                            WHERE OrderId IN :orderIds];

        System.debug('**************OrderItemDetails: ' + orderItemDetails);
        
        if (orderItemDetails.isEmpty()) {
            System.debug('OrderItem is empty');
        }

        List<Quote> quotesToInsert = new List<Quote>();
        List<QuoteLineItem> quoteLineItemsToInsert = new List<QuoteLineItem>();

        // Loop over order data to create quotes and quote line items
        for (Order o : orderData) {
               System.debug('**************OrderData: ' + orderData);
            if(o.Bundle_Quantity__c>0){
                for(Decimal i=1;i<=o.Bundle_Quantity__c;i++){
                     Quote quote = new Quote();
                            quote.Name = o.Name;
                            quote.Pricebook2Id = o.Pricebook2Id;
                            quote.Delivery_Date__c = o.EffectiveDate;
                            quote.OrderId__c = o.Id;
                            quote.QuoteAccountId = o.AccountId;
                            quotesToInsert.add(quote);
                }
            }else{
                Quote quote = new Quote();
                            quote.Name = o.Name;
                            quote.Pricebook2Id = o.Pricebook2Id;
                            quote.Delivery_Date__c = o.EffectiveDate;
                            quote.OrderId__c = o.Id;
                            quote.QuoteAccountId = o.AccountId;
                            quotesToInsert.add(quote);
            }
            for (OrderItem item : orderItemDetails) {
               		
                    if (item.Product_Type__c == 'Blank') {
                        System.debug('Creating a single Quote for Blank Product_Type__c');

                        QuoteLineItem quoteLineItem = new QuoteLineItem();
                        quoteLineItem.Quantity = item.Quantity;
                        quoteLineItem.UnitPrice = item.UnitPrice;
                        quoteLineItem.Product2Id = item.Product2Id;
                        quoteLineItem.PricebookEntryId = item.PricebookEntryId;
                        quoteLineItem.S__c = item.S__c;
                        quoteLineItem.M__c = item.M__c;
                        quoteLineItem.L__c = item.L__c;
                        quoteLineItem.XL__c = item.XL__c;
                        quoteLineItem.XXL__c = item.XXL__c;
                        quoteLineItem.XXXL__c = item.XXXL__c;
                        quoteLineItem.Description = item.Description;
                        quoteLineItem.Product_Type__c=item.Product_Type__c; 
                        quoteLineItemsToInsert.add(quoteLineItem);

                    }

                   else if (item.Product_Type__c == 'Catalogue') {
                        
                       
                            // Create the corresponding QuoteLineItem
                            for(Decimal i=1;i<=o.Bundle_Quantity__c;i++){
                            QuoteLineItem quoteLineItem = new QuoteLineItem();
                            quoteLineItem.Quantity = item.Quantity; 
                            quoteLineItem.UnitPrice = item.UnitPrice;
                            quoteLineItem.Product2Id = item.Product2Id;
                            quoteLineItem.PricebookEntryId = item.PricebookEntryId;
                            quoteLineItem.S__c = item.S__c;
                            quoteLineItem.M__c = item.M__c;
                            quoteLineItem.L__c = item.L__c;
                            quoteLineItem.XL__c = item.XL__c;
                            quoteLineItem.XXL__c = item.XXL__c;
                            quoteLineItem.XXXL__c = item.XXXL__c;
                            quoteLineItem.Description = item.Description;
                            quoteLineItem.Product_Type__c=item.Product_Type__c; 
                            quoteLineItemsToInsert.add(quoteLineItem);
                            }
                    }
                    else{
                        System.debug('product type is not capturing');
                    }
                
            }
        }

        
        if (!quotesToInsert.isEmpty()) {
            try {
                insert quotesToInsert;
                System.debug('Inserted Quotes: ' + quotesToInsert);
            } catch (DmlException e) {
                System.debug('Error inserting Quotes: ' + e.getMessage());
            }
        }

        if (!quoteLineItemsToInsert.isEmpty()) {
            System.debug(quoteLineItemsToInsert.size());
            Integer quoteIndex = 0;
                    for (QuoteLineItem qli : quoteLineItemsToInsert) {
                        qli.QuoteId = quotesToInsert[quoteIndex].Id;
                        quoteIndex++;
                if (quoteIndex >= quotesToInsert.size()) {
                    quoteIndex = 0;
                }
                      
                    }
               
            }


           
        
        if(!quoteLineItemsToInsert.isEmpty()){
             try {
                insert quoteLineItemsToInsert;
                System.debug('Inserted QuoteLineItems: ' + quoteLineItemsToInsert);
            } catch (DmlException e) {
                System.debug('Error inserting QuoteLineItems: ' + e.getMessage());
            }
        }
    }
}