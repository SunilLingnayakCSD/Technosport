public with sharing class OrderPDFController {

    /* ------------------------------------------------------------------
     * 1. Data for LWC  (cacheable)
     * ------------------------------------------------------------------ */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getInvoiceJSON(Id visitId) {
        // if (visitId == null) throw new AuraHandledException('visitId is required');

        OrderPDFController ctrl = new OrderPDFController(visitId);  // now valid
        Map<String, Object> payload = new Map<String, Object>();

        payload.put('invoiceDate', ctrl.invoiceDate);
        payload.put('order',       ctrl.order);
        payload.put('items',       ctrl.items);
        payload.put('billTo',      ctrl.billTo);
        payload.put('shipTo',      ctrl.shipTo);

        return payload;
    }

    /* ------------------------------------------------------------------
     * 2. Persist PDF coming from LWC
     * ------------------------------------------------------------------ */
   
    @AuraEnabled(cacheable=false)
    public static void savePdfToVisit(Id visitId, String base64Data, String fileName) {
        if (String.isBlank(base64Data) || visitId == null) {
            throw new AuraHandledException('Missing data or visit ID');
        }

        Attachment a = new Attachment();
        a.ParentId = visitId;
        a.Name = fileName;
        a.Body = EncodingUtil.base64Decode(base64Data);
        a.ContentType = 'application/pdf';
        insert a;
    }


    
    @AuraEnabled
    public static Id savePdfAttachment(Id visitId, String fileName, String pdfBase64) {
        if (String.isBlank(pdfBase64) || visitId == null)
            throw new AuraHandledException('Missing data for PDF save');

        Attachment att = new Attachment();
        att.ParentId = visitId;
        att.Name     = String.isBlank(fileName) ? 'Invoice.pdf' : fileName;
        att.Body     = EncodingUtil.base64Decode(pdfBase64.substringAfter(',')); // strip data URI header if present
        insert att;

        return att.Id;
    }

    // Wrapper for items
    public class OrderItemWrapper {
        public Integer SrNo        { get; set; }
        public String  ProductName { get; set; }
        public String  HsnSac      { get; set; }
        public Decimal Quantity    { get; set; }
        public Decimal UnitPrice   { get; set; }
        public Decimal LineAmount  { get; set; }
    }

    public Order                  order       { get; private set; }
    public List<OrderItemWrapper> items       { get; private set; }
    public String                 invoiceDate { get { return Date.today().format(); } }
    public String                 billTo      { get; private set; }
    public String                 shipTo      { get; private set; }
    public Account                acc         { get; private set; }
    public String                 retailerName { get; private set; }
   

    // Default constructor for Visualforce/ApexPages
    public OrderPDFController() {
        Id visitId = ApexPages.currentPage().getParameters().get('visitId');
        if (visitId == null) throw new AuraHandledException('Visit Id missing');
        init(visitId);
    }

    // ✅ Constructor for LWC call
    public OrderPDFController(Id visitId) {
        if (visitId == null) throw new AuraHandledException('Visit Id missing');
        init(visitId);
    }

    // Common initialization logic
    private void init(Id visitId) {
        // Query latest Order for the Visit
        order = [
            SELECT Id, OrderNumber, TotalAmount, AccountId, Account.Name, PoDate,Retailer_Account__r.Name,
                   BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                   ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry
            FROM Order
            WHERE Visit__c = :visitId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        acc = [
            SELECT Id,
                   BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                   ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry
            FROM Account
            WHERE Id = :order.AccountId
        ];
        retailerName = (order.Retailer_Account__r == null) ? null : order.Retailer_Account__r.Name;
        buildAddresses();
        buildItems();
    }
    

    private void buildAddresses() {
        billTo = formatAddr(acc.BillingStreet, acc.BillingCity,
                            acc.BillingState, acc.BillingPostalCode,
                            acc.BillingCountry);

        shipTo = formatAddr(acc.ShippingStreet, acc.ShippingCity,
                            acc.ShippingState, acc.ShippingPostalCode,
                            acc.ShippingCountry);
    }

    private String formatAddr(String st, String c, String s, String pc, String cntry) {
        List<String> raw = new List<String>{ st, c, s, pc, cntry };
        List<String> clean = new List<String>();
        for (String p : raw)
            if (String.isNotBlank(p)) clean.add(p.trim());
        return String.join(clean, ', ');
    }

    private void buildItems() {
        items = new List<OrderItemWrapper>();
        Integer counter = 1;

        for (OrderItem oi : [
            SELECT Quantity, UnitPrice, TotalPrice,
                   PricebookEntry.Product2.Name, PricebookEntry.Product2.HSN_SAC_Code__c
            FROM OrderItem
            WHERE OrderId = :order.Id
        ]) {
            OrderItemWrapper w = new OrderItemWrapper();
            w.SrNo         = counter++;
            w.ProductName  = oi.PricebookEntry.Product2.Name;
            w.HsnSac       = oi.PricebookEntry.Product2.HSN_SAC_Code__c;
            w.Quantity     = oi.Quantity;
            w.UnitPrice    = oi.UnitPrice;
            w.LineAmount   = oi.TotalPrice;
            items.add(w);
        }
    }

    // Add generateAndAttach methods here if needed

}