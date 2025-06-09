public with sharing class OrderController {
    @AuraEnabled(cacheable=true)
    public static List<OrderWrapper> fetchOrders() {
        List<OrderWrapper> ordersList = new List<OrderWrapper>();

        // Check if the current user is an admin
        Boolean isAdmin = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Profile.Name == 'System Administrator';

        String userAccountId = null;

        // If the user is not an admin, get the AccountId associated with the logged-in user
        if (!isAdmin) {
            userAccountId = [SELECT AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].AccountId;
        }

        // Query based on user type
        List<Order> orders;
        if (isAdmin) {
            // Admin can see all orders
            orders = [SELECT Id, OrderNumber, Name, Status, AccountId,
                            (SELECT Id, Product2.Name, Quantity FROM OrderItems)
                     FROM Order
                     WHERE Status IN ('Draft','Activated', 'Sales Order', 'Invoice') AND AccountId!=''
                     ORDER BY CreatedDate DESC];
        } else {
            // Non-admin can only see orders belonging to their AccountId
            orders = [SELECT Id, OrderNumber, Name, Status, AccountId,
                            (SELECT Id, Product2.Name, Quantity FROM OrderItems)
                     FROM Order
                     WHERE AccountId = :userAccountId AND Status IN ('Draft','Activated', 'Sales Order', 'Invoice')
                     ORDER BY CreatedDate DESC];
        }

        // Populate the wrapper list with order data
        for (Order ord : orders) {
            OrderWrapper ow = new OrderWrapper();
            ow.orderId = ord.Id;
            ow.orderNumber = ord.OrderNumber;
            ow.orderName = ord.Name;
            ow.status = ord.Status;
            ow.orderItems = new List<OrderItemWrapper>();

            for (OrderItem item : ord.OrderItems) {
                ow.orderItems.add(new OrderItemWrapper(item.Product2.Name, (Integer)item.Quantity));
            }

            ordersList.add(ow);
        }
        return ordersList;
    }

    public class OrderWrapper {
        @AuraEnabled public String orderId;
        @AuraEnabled public String orderNumber;
        @AuraEnabled public String orderName;
        @AuraEnabled public String status;
        @AuraEnabled public List<OrderItemWrapper> orderItems;
    }

    public class OrderItemWrapper {
        @AuraEnabled public String itemName;
        @AuraEnabled public Integer quantity;

        public OrderItemWrapper(String name, Integer qty) {
            this.itemName = name;
            this.quantity = qty;
        }
    }
}