public with sharing class OrderCountApexClass {

    public class OrderWrapper {
        @AuraEnabled public String orderId;
        @AuraEnabled public Decimal orderAge;
        @AuraEnabled public Date orderDate;
        @AuraEnabled public String orderNumber;
        @AuraEnabled public List<OrderItem> orderLineItem;
        @AuraEnabled public Integer quoteNotInInvoice;

    }

    @AuraEnabled(cacheable=true)
    public static List<OrderWrapper> getOrderDetails() {
        Id currentUserId = UserInfo.getUserId();
        System.debug('Current User Id: ' + currentUserId);

        // Step 1: Get the logged-in user and ContactId
        User currentUser = [SELECT ContactId FROM User WHERE Id = :currentUserId LIMIT 1];

        if (currentUser.ContactId == null) {
            System.debug('No ContactId associated with the logged-in user.');
            return new List<OrderWrapper>();
        }

        // Step 2: Get AccountId from Contact
        Contact userContact = [SELECT AccountId FROM Contact WHERE Id = :currentUser.ContactId LIMIT 1];

        if (userContact.AccountId == null) {
            System.debug('No Account associated with Contact.');
            return new List<OrderWrapper>();
        }

        Id accountId = userContact.AccountId;

        // Step 3: Get RecordTypeId for Purchase Order
        Id purchaseOrderRecordTypeId = [
            SELECT Id FROM RecordType 
            WHERE SObjectType = 'Order' AND Name = 'Purchase Order' 
            LIMIT 1
        ].Id;

        // Step 4: Fetch Orders for the Account with Purchase Order record type
        List<Order> orders = [
            SELECT Id, OrderNumber,CreatedDate,Order_Age__c,
                (SELECT Id, Product2Id, Product2.Name,Product2.Product_Template__r.Name,Quantity FROM OrderItems ),(SELECT Id, Status 
            FROM Quotes__r Where Status='Reserved') 
            FROM Order
            WHERE AccountId = :accountId 
              AND RecordTypeId = :purchaseOrderRecordTypeId
            ORDER BY CreatedDate DESC
        ];
System.debug('orders'+orders);
        if (orders.isEmpty()) {
            System.debug('No Orders found for Account.');
            return new List<OrderWrapper>();
        }

        List<OrderWrapper> result = new List<OrderWrapper>();

        for (Order ord : orders) {
            OrderWrapper wrapper = new OrderWrapper();
            wrapper.orderId=ord.Id;
            wrapper.orderAge=ord.Order_Age__c;
            wrapper.orderDate=Date.valueOf(ord.CreatedDate);
            wrapper.orderNumber = ord.OrderNumber;
            wrapper.orderLineItem = ord.OrderItems;
            
            wrapper.quoteNotInInvoice=ord.Quotes__r.size();
			

            result.add(wrapper);
        }

        System.debug('Returning OrderWrapper List: ' + result);
        return result;
    }
}