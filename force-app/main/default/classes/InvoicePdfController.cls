public class InvoicePdfController {
    
    public Invoice__c invoice { get; set; }
    public List<Invoice_Line_Item__c> invoiceItems { get; set; }
    public String name { get; set; }
    public String invoiceDate { get; set; }
    public String dueDate { get; set; }
    public String deliveryDate { get; set; }
    public String source { get; set; }
    public String reference { get; set; }
    public String ewayBillNo { get; set; }
    public List<Map<String, Object>> hsnSummary { get; set; }
    
  /*  public List<String> description { get; set; }
    public List<String> HSNSAC { get; set; }
    public List<String> quantity { get; set; }
    public List<String> unitPrice { get; set; }
    public List<String> tax { get; set; }
    public List<String> amount { get; set; }
    
    public Decimal untaxedAmount { get; set; }
    public Decimal totalAmount { get; set; }*/
    
    // Constructor to initialize data
    public InvoicePdfController(ApexPages.StandardController controller) {
     /*   // Initialize lists to prevent null pointer errors
        description = new List<String>();
        HSNSAC = new List<String>();
        quantity = new List<String>();
        unitPrice = new List<String>();
        tax = new List<String>();
        amount = new List<String>();
        hsnSummary = new List<Map<String, Object>>();*/
        
        // Get the Invoice details using the 'id' parameter
        String invoiceId = ApexPages.currentPage().getParameters().get('id');
        if (invoiceId != null) {
            invoice = [SELECT Id, Name, Invoice_Date__c, Due_Date__c, Delivery_Date__c, Source__c, Reference__c, E_Way_Bill_No__c
                       FROM Invoice__c WHERE Id = :invoiceId];

            system.debug(' invoice' + invoice);
        }
        
        // Get Invoice Items related to the Invoice
        if (invoice != null) {
            invoiceItems = [SELECT Description__c, HSN_SAC__c, Quantity__c, Unit_Price__c, Taxes__c, Amount__c
                            FROM Invoice_Line_Item__c WHERE Invoice__c = :invoice.Id];

            system.debug(' invoiceItems' + invoiceItems);
        }
        
    /*    // Initialize totals
        untaxedAmount = 0;
        totalAmount = 0;
        
        // For storing HSN data in a map for summarization
        Map<String, Map<String, Decimal>> hsnData = new Map<String, Map<String, Decimal>>();
        
        // Loop through the invoice line items to collect the necessary data
        for (Invoice_Line_Item__c item : invoiceItems) {
            // Add each item's data to the lists
            description.add(item.Description__c);
            HSNSAC.add(item.HSN_SAC__c);
            quantity.add(String.valueOf(item.Quantity__c));  // Convert to String for display
            unitPrice.add(String.valueOf(item.Unit_Price__c));  // Convert to String for display
            tax.add(String.valueOf(item.Taxes__c));  // Convert to String for display
            amount.add(String.valueOf(item.Amount__c));  // Convert to String for display
            
            // Update total amounts
            untaxedAmount += item.Amount__c;
            totalAmount += item.Amount__c;
            
            // Store HSN data in a map to group by HSN/SAC code
            if (!hsnData.containsKey(item.HSN_SAC__c)) {
                hsnData.put(item.HSN_SAC__c, new Map<String, Decimal>{'Quantity' => 0, 'TaxableValue' => 0, 'IGST' => 0});
            }
            
            // Accumulate HSN data
            hsnData.get(item.HSN_SAC__c).put('Quantity', hsnData.get(item.HSN_SAC__c).get('Quantity') + item.Quantity__c);
            hsnData.get(item.HSN_SAC__c).put('TaxableValue', hsnData.get(item.HSN_SAC__c).get('TaxableValue') + item.Amount__c);
            
            // Assuming 18% IGST (you can modify this logic as needed)
            hsnData.get(item.HSN_SAC__c).put('IGST', hsnData.get(item.HSN_SAC__c).get('IGST') + (item.Amount__c * 0.18)); // Example, modify if necessary
        }
        
        // Convert the HSN data to the required summary format
        for (String hsnCode : hsnData.keySet()) {
            Map<String, Object> summary = new Map<String, Object>();
            summary.put('HSNSAC', hsnCode);
            summary.put('Quantity', hsnData.get(hsnCode).get('Quantity'));
            summary.put('TaxableValue', hsnData.get(hsnCode).get('TaxableValue'));
            summary.put('IGST', hsnData.get(hsnCode).get('IGST'));
            
            // Add tax rate (you can adjust this calculation based on your requirement)
            summary.put('Rate', 18);  // Assuming a fixed rate of 18%, change if necessary
            
            // Add the summary to the hsnSummary list
            hsnSummary.add(summary);
        }*/
        
        // Set the invoice data for the Visualforce page
        if (invoice != null) {
            name = invoice.Name;
            invoiceDate = (invoice.Invoice_Date__c != null) ? invoice.Invoice_Date__c.format() : 'N/A';
            dueDate = (invoice.Due_Date__c != null) ? invoice.Due_Date__c.format() : 'N/A';
            deliveryDate = (invoice.Delivery_Date__c != null) ? invoice.Delivery_Date__c.format() : 'N/A';
            source = invoice.Source__c;
            reference = invoice.Reference__c;
            ewayBillNo = invoice.E_Way_Bill_No__c;
        }
    }
}