public class EWayBillController {
    public Invoice__c invoice { get; set; }
    public String invoiceName { get; set; }
    public String invoiceId { get; set; }
    public String IRN { get; set; }
    public String AckNo { get; set; }
    public String AckDate { get; set; }
    public String EWayBillNo { get; set; }
    public String EWayBillDate { get; set; }
    public String GeneratedBy { get; set; }
    public String ValidBy { get; set; }
    public String ValidUntil { get; set; }
    public String GSTINofSupplier { get; set; }
    public String PlaceOfDispatch { get; set; }
    public String GSTINofRecipient { get; set; }
    public String PlaceOfDelivery { get; set; }
    public String DocumentNo { get; set; }
    public String DocumentDate { get; set; }
    public String TransactionType { get; set; }
    public String ValueOfGoods { get; set; }
    public String HSNCode { get; set; }
    public String ReasonForTransportation { get; set; }
    public String Transporter { get; set; }

    public EWayBillController(ApexPages.StandardController controller) {
       
        // Retrieve the 'id' parameter from the URL
        String invoiceId = ApexPages.currentPage().getParameters().get('id');
        system.debug('recordId--'+invoiceId);

        if (invoiceId != null) {
            // Query the Invoice__c record and populate fields
            invoice = [SELECT Id, Name,E_Way_Bill_No__c , E_Way_Bill_Date__c,Generated_By__c,Valid_By__c,Valid_Until__c,GSTIN_of_Supplier__c,Place_of_Dispatch__c,GSTIN_of_Recipient__c,Place_of_Delivery__c, Document_No__c,Document_Date__c, Transcartion_Type__c,Value_of_Goods__c,HSN_Code__c,Reason_for_Transportation__c,Transporter__c     
                   FROM Invoice__c WHERE Id = :ApexPages.currentPage().getParameters().get('id')];
          
            system.debug(' invoice'+ invoice);
            
        }
        if (invoice != null) {
    InvoiceName = invoice.Name;
    ewayBillNo = invoice.E_Way_Bill_No__c;
    ewayBillDate = (invoice.E_Way_Bill_Date__c != null) ? invoice.E_Way_Bill_Date__c.format() : 'N/A';
    generatedBy = invoice.Generated_By__c;
    validBy = (invoice.Valid_By__c != null) ? invoice.Valid_By__c.format() : 'N/A';
    validUntil = (invoice.Valid_Until__c != null) ? invoice.Valid_Until__c.format() : 'N/A';
    gstinOfSupplier = invoice.GSTIN_of_Supplier__c;
    placeOfDispatch = invoice.Place_of_Dispatch__c;
    gstinOfRecipient = invoice.GSTIN_of_Recipient__c;
    placeOfDelivery = invoice.Place_of_Delivery__c;
    documentNo = invoice.Document_No__c;
    documentDate = (invoice.Document_Date__c != null) ? invoice.Document_Date__c.format() : 'N/A';
    transactionType = invoice.Transcartion_Type__c;
     valueOfGoods = (invoice.Value_of_Goods__c != null) ? String.valueOf(invoice.Value_of_Goods__c) : 'N/A'; // Convert Decimal to String
    hsnCode = invoice.HSN_Code__c;
    reasonForTransportation = invoice.Reason_for_Transportation__c;
    transporter = invoice.Transporter__c;
}

}
}