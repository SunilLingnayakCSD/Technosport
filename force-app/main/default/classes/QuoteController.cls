public  class QuoteController {

    
@AuraEnabled(cacheable=true)
public static List<OrderWrapper> getOrderSummaryData(Date startDate, Date endDate) {
    List<OrderWrapper> results = new List<OrderWrapper>();

    Id currentUserId = UserInfo.getUserId();
    System.debug('Current User Id: ' + currentUserId);

   
    User currentUser = [SELECT ContactId FROM User WHERE Id = :currentUserId LIMIT 1];

    if (currentUser.ContactId == null) {
        System.debug('No ContactId associated with the logged-in user.');
        return new List<OrderWrapper>();
    }

    Contact userContact = [SELECT AccountId FROM Contact WHERE Id = :currentUser.ContactId LIMIT 1];

    if (userContact.AccountId == null) {
        System.debug('No Account associated with Contact.');
        return new List<OrderWrapper>();
    }

    Id accountId = userContact.AccountId;

    List<Order> orders = [
        SELECT Id, Order_Created_Date__c, Description, AccountId, CreatedDate,ratio__c,Sizes__c,(SELECT Id,Product2.Product_Template__r.Name,Description FROM OrderItems limit 1)
        FROM Order
        WHERE Status = 'Activated'
        AND AccountId = :accountId
        AND CreatedDate >= :startDate AND CreatedDate <= :endDate
        ORDER BY CreatedDate DESC
    ];

    Set<Id> orderIds = new Set<Id>();
    for (Order ord : orders) {
        orderIds.add(ord.Id);
    }


    List<Quote> quotes = [
        SELECT Id, Name, OrderId__c, Status,Description,Ratio__c,
            (SELECT Id, Product2.Name,Product2.Product_Template__r.Name, Product2.Description FROM QuoteLineItems limit 1)
        FROM Quote
        WHERE OrderId__c IN :orderIds
    ];

    Map<Id, List<Quote>> orderToQuotes = new Map<Id, List<Quote>>();
    for (Quote q : quotes) {
        if (!orderToQuotes.containsKey(q.OrderId__c)) {
            orderToQuotes.put(q.OrderId__c, new List<Quote>());
        }
        orderToQuotes.get(q.OrderId__c).add(q);
    }

    for (Order ord : orders) {
        OrderWrapper orderWrap = new OrderWrapper();
        orderWrap.orderId = ord.Id;
        orderWrap.orderDate = ord.Order_Created_Date__c;
        orderWrap.orderDescription = ord.Description;
        orderWrap.Ratio=ord.Ratio__c;
        orderWrap.sizes=ord.Sizes__c;

        for (OrderItem item : ord.OrderItems) {
            OrderItemWrapper itemWrap = new OrderItemWrapper();
            itemWrap.productName = item.Product2.Product_Template__r.Name; // Or item.Product2.Name if needed
            itemWrap.description = item.Description;
            orderWrap.orderItems.add(itemWrap);
            break;
        }

        List<Quote> relatedQuotes = orderToQuotes.get(ord.Id);
        if (relatedQuotes != null) {
            orderWrap.quoteCount = relatedQuotes.size();

            for (Quote q : relatedQuotes) {
                QuoteWrapper quoteWrap = new QuoteWrapper();
                quoteWrap.quoteId = q.Id;
                quoteWrap.quoteName = q.Name;

                if (q.Status == 'Cancelled') {
                    orderWrap.cancelledCount++;
                } else if (q.Status == 'Dispatch') {
                    orderWrap.invoiceCount++;
                } else if (q.Status == 'Reserved') {
                    orderWrap.reservedCount++;
                }

                for (QuoteLineItem qli : q.QuoteLineItems) {
                    QuoteLineItemWrapper qliWrap = new QuoteLineItemWrapper();
                   // qliWrap.productName = qli.Product2 != null ? qli.Product2.Name : null;
                   // qliWrap.description = qli.Description != null ? qli.Description : null;
                    quoteWrap.quoteLineItems.add(qliWrap);
                }

                orderWrap.quotes.add(quoteWrap);
            }
        } else {
            orderWrap.quoteCount = 0;
        }

        results.add(orderWrap);
    }

    System.debug('results--->' + results);
    return results;
}

// Wrapper Classes

public class OrderWrapper {
    @AuraEnabled public String orderId;
    @AuraEnabled public Date orderDate;
    @AuraEnabled public String orderDescription;
    @AuraEnabled public Integer quoteCount;
    @AuraEnabled public Integer cancelledCount;
    @AuraEnabled public Integer invoiceCount;
    @AuraEnabled public Integer onHoldCount;
    @AuraEnabled public Integer reservedCount;
    @AuraEnabled public List<QuoteWrapper> quotes;
    @AuraEnabled public List<OrderItemWrapper> orderItems;
    @AuraEnabled public String sizes;
    @AuraEnabled public String Ratio;

    public OrderWrapper() {
        this.cancelledCount = 0;
        this.invoiceCount = 0;
        this.onHoldCount = 0;
        this.reservedCount = 0;
        this.quotes = new List<QuoteWrapper>();
        this.orderItems = new List<OrderItemWrapper>();
        this.Ratio = '';
        this.sizes = '';
    }
}

public class QuoteWrapper {
    @AuraEnabled public String quoteId;
    @AuraEnabled public String quoteName;
    @AuraEnabled public List<QuoteLineItemWrapper> quoteLineItems;

    public QuoteWrapper() {
        this.quoteLineItems = new List<QuoteLineItemWrapper>();
    }
}

public class QuoteLineItemWrapper {
    @AuraEnabled public String productName;
    @AuraEnabled public String description;
    @AuraEnabled public String status;
}

public class OrderItemWrapper {
    @AuraEnabled public String productName;
    @AuraEnabled public String description;
} 

}