public with sharing class ProductOrderController {
    @AuraEnabled(cacheable=true)
    public static List<OrderProductWrapper> getFrequentlyOrderedProducts() {
        // Query to fetch the ordered product data including product image URL and name.
        List<Order> orders = [
            SELECT Id, OrderNumber, CreatedDate, 
                (SELECT Product2.Name, Product2.Id FROM OrderItems)
            FROM Order 
            WHERE Status = 'Invoice'
        ];

        List<OrderProductWrapper> result = new List<OrderProductWrapper>();

        // Loop through the orders and get the product details.
        for(Order ord : orders) {
            for(OrderItem oi : ord.OrderItems) {
                // Pass product name, product image URL, and order date to the wrapper class
                result.add(new OrderProductWrapper(
                    oi.Product2.Name ,
                    ord.CreatedDate
                ));
            }
        }

        return result;
    }
    
    public class OrderProductWrapper {
        @AuraEnabled public String productName;
        @AuraEnabled public String orderDate;

        // Constructor to initialize product details and order date
        public OrderProductWrapper(String name, DateTime orderedDate) {
            this.productName = name;
            this.orderDate = orderedDate.format();  // Format the order date properly
        }
    }
}