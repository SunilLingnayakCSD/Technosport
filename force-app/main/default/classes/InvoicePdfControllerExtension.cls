public with sharing class InvoicePdfControllerExtension {

    public Invoice__c invoice { get; private set; }
    public List<Invoice_Line_Item__c> lineItems { get; private set; }

    // Constructor to initialize the controller
    public InvoicePdfControllerExtension(ApexPages.StandardController stdController) {
        // Retrieve the invoice record
        this.invoice = (Invoice__c)stdController.getRecord();
        
        // Query related line items
        this.lineItems = [SELECT Id, Name, Unit_Price__c, HSN_SAC__c, Amount__c, Quantity__c, Invoice__c, Taxes__c FROM Invoice_Line_Item__c
                          WHERE Invoice__c = :invoice.Id];
        
        // Check if lineItems is null
        if (this.lineItems == null) {
            this.lineItems = new List<Invoice_Line_Item__c>();
        }
    }

    // Method to format the date in the required format
    public String getFormattedDate() {
        return Datetime.now().format('dd-MM-yyyy');
    }

    // Method to calculate the total amount
    public Decimal getTotalAmount() {
        Decimal totalPrice = 0;
        if (lineItems != null && !lineItems.isEmpty()) {
            for (Invoice_Line_Item__c item : lineItems) {
                if (item.Amount__c != null) {
                    totalPrice += item.Amount__c;
                }
            }
        }
        return totalPrice;
    }


}