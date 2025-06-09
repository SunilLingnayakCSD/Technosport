public class CreateQuoteController {
    public static void createQuote(List<Order> orderData) {
        System.debug('**************InsideOrderCreate ' + orderData);
        
        if (orderData.isEmpty()) {
            System.debug('No orders provided.');
            return;
        }

        Set<Id> orderIds = new Set<Id>();
        for (Order o : orderData) {
            orderIds.add(o.Id);
        }

        List<OrderItem> orderItemDetails = [SELECT Id, OrderId, Product2Id, PricebookEntryId, Quantity, UnitPrice, ListPrice,isUpcomingVarient__c, 
                                            S__c, M__c, L__c, XL__c, XXL__c, XXXL__c, Colors__c, Description, Product_Type__c 
                                            FROM OrderItem 
                                            WHERE OrderId IN :orderIds];

        System.debug('**************OrderItemDetails: ' + orderItemDetails);

        List<Quote> quotesToInsert = new List<Quote>();
        List<Quote> futureQuotesToInsert = new List<Quote>();
        List<QuoteLineItem> quoteLineItemsToInsert = new List<QuoteLineItem>();
        List<QuoteLineItem> futurequoteLineItemsToInsert = new List<QuoteLineItem>();

        for (Order o : orderData) {
            Decimal bundleQty = o.Bundle_Quantity__c == null ? 0 : o.Bundle_Quantity__c;

            if (bundleQty > 0) {
                for (Decimal i = 1; i <= bundleQty; i++) {
                    Quote quote = new Quote();
                    quote.Name = o.Name;
                    quote.Pricebook2Id = o.Pricebook2Id;
                    quote.Delivery_Date__c = o.EffectiveDate;
                    quote.OrderId__c = o.Id;
                    quote.QuoteAccountId = o.AccountId;
                    quote.Description = o.Description;
                    quote.isNextAvailbleProductQuote__c=o.isFutureProduct__c;
                    quotesToInsert.add(quote);
                }
				System.debug('o.isFutureQuoShouuldCreate__c'+o.isFutureQuoShouuldCreate__c);
                if (o.isFutureQuoShouuldCreate__c == true) {
                    
                    Quote futureQuote = new Quote();
                    futureQuote.Name = o.Name;
                    futureQuote.Pricebook2Id = o.Pricebook2Id;
                    futureQuote.Delivery_Date__c = o.EffectiveDate;
                    futureQuote.OrderId__c = o.Id;
                    futureQuote.QuoteAccountId = o.AccountId;
                    futureQuote.Description = o.Description;
                    futureQuote.isNextAvailbleProductQuote__c=o.isFutureQuoShouuldCreate__c;
                    futureQuotesToInsert.add(futureQuote);
                }
            } else {
                Quote quote = new Quote();
                quote.Name = o.Name;
                quote.Pricebook2Id = o.Pricebook2Id;
                quote.Delivery_Date__c = o.EffectiveDate;
                quote.OrderId__c = o.Id;
                quote.QuoteAccountId = o.AccountId;
                quote.Description = o.Description;
                quote.isNextAvailbleProductQuote__c=o.isFutureProduct__c;
                quotesToInsert.add(quote);
            }

            for (OrderItem item : orderItemDetails) {
                if (item.Product_Type__c == 'Blank') {
                    QuoteLineItem qli = new QuoteLineItem();
                    qli.Quantity = item.Quantity;
                    qli.UnitPrice = item.UnitPrice;
                    qli.Product2Id = item.Product2Id;
                    qli.PricebookEntryId = item.PricebookEntryId;
                    qli.isUpcomingVarient__c = item.isUpcomingVarient__c;
                    qli.Description = item.Description;
                    qli.Product_Type__c = item.Product_Type__c;
                    quoteLineItemsToInsert.add(qli);
                } else if (item.Product_Type__c == 'Catalogue') {
                    if (item.isUpcomingVarient__c == true) {
                        QuoteLineItem fqli = new QuoteLineItem();
                        fqli.Quantity = item.Quantity;
                        fqli.UnitPrice = item.UnitPrice;
                        fqli.Product2Id = item.Product2Id;
                        fqli.PricebookEntryId = item.PricebookEntryId;
                        fqli.isUpcomingVarient__c = item.isUpcomingVarient__c;
                        fqli.Description = item.Description;
                        fqli.Product_Type__c = item.Product_Type__c;
                        futurequoteLineItemsToInsert.add(fqli);
                    } else {
                        for (Decimal i = 1; i <= bundleQty; i++) {
                            QuoteLineItem qli = new QuoteLineItem();
                            qli.Quantity = item.Quantity;
                            qli.UnitPrice = item.UnitPrice;
                            qli.Product2Id = item.Product2Id;
                            qli.PricebookEntryId = item.PricebookEntryId;
                            qli.isUpcomingVarient__c = item.isUpcomingVarient__c;
                            qli.Description = item.Description;
                            qli.Product_Type__c = item.Product_Type__c;
                            quoteLineItemsToInsert.add(qli);
                        }
                    }
                } else {
                    System.debug('Unknown product type: ' + item.Product_Type__c);
                }
            }
        }

        if (!quotesToInsert.isEmpty() && !quoteLineItemsToInsert.isEmpty()) {
            try {
                insert quotesToInsert;
                System.debug('Inserted Quotes: ' + quotesToInsert);
            } catch (DmlException e) {
                System.debug('Error inserting Quotes: ' + e.getMessage());
            }
        }

        if (!quoteLineItemsToInsert.isEmpty() && !quotesToInsert.isEmpty()) {
            Integer quoteIndex = 0;
            for (QuoteLineItem qli : quoteLineItemsToInsert) {
                qli.QuoteId = quotesToInsert[quoteIndex].Id;
                quoteIndex++;
                if (quoteIndex >= quotesToInsert.size()) {
                    quoteIndex = 0;
                }
            }
        } else {
            System.debug('Skipping QuoteLineItem QuoteId assignment due to empty list.');
        }

        if (!quoteLineItemsToInsert.isEmpty()) {
            try {
                insert quoteLineItemsToInsert;
                System.debug('Inserted QuoteLineItems: ' + quoteLineItemsToInsert);
            } catch (DmlException e) {
                System.debug('Error inserting QuoteLineItems: ' + e.getMessage());
            }
        }

        if (!futureQuotesToInsert.isEmpty() && !futurequoteLineItemsToInsert.isEmpty()) {
            try {
                insert futureQuotesToInsert;
                System.debug('Inserted Future Quotes: ' + futureQuotesToInsert);
            } catch (DmlException e) {
                System.debug('Error inserting Future Quotes: ' + e.getMessage());
            }
        }

        if (!futurequoteLineItemsToInsert.isEmpty() && !futureQuotesToInsert.isEmpty()) {
            Integer futureIndex = 0;
            for (QuoteLineItem fqli : futurequoteLineItemsToInsert) {
                fqli.QuoteId = futureQuotesToInsert[futureIndex].Id;
                futureIndex++;
                if (futureIndex >= futureQuotesToInsert.size()) {
                    futureIndex = 0;
                }
            }
        } else {
            System.debug('Skipping future QuoteLineItem QuoteId assignment due to empty list.');
        }

     
        if (!futurequoteLineItemsToInsert.isEmpty()) {
            try {
                insert futurequoteLineItemsToInsert;
                System.debug('Inserted Future QuoteLineItems: ' + futurequoteLineItemsToInsert);
            } catch (DmlException e) {
                System.debug('Error inserting Future QuoteLineItems: ' + e.getMessage());
            }
        }
    }
}