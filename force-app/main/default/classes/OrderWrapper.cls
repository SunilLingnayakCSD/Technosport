public class OrderWrapper {

    public String partnerId;
    public String orderStartDate; 
    public Decimal bundleQuantity;
    public String ratio;
    public String sizes;
    public String orderSource;
    public List<OrderLineItem> orderLineItems;
    public List<QuoteWrapper> quotes;

    public class OrderLineItem {
        public String productId;
        public String productType;
        public Decimal quantity;
        public Decimal unitPrice;
        public String color;
    }

    public class QuoteWrapper {
        public String odooQuoteId;
        public String quoteName;
        public String deliveryDate; // Use DateTime if needed
        public String partnerId;
        public List<QuoteLineItem> quoteLineItems;
    }

    public class QuoteLineItem {
        public String productId;
        public String productType;
        public Decimal quantity;
        public Decimal unitPrice;
       
    }
}