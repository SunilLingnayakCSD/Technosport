@isTest
public class InvoicePdfControllerExtensionTest {

    // Helper method to create test data dynamically
    private static Invoice__c createInvoiceWithLineItems(Integer numberOfItems) {
        // Create and insert an Invoice record
          Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Invoice__c invoice = new Invoice__c(
            Name = 'Test Invoice ' + String.valueOf(System.currentTimeMillis()), // Convert to String
            // Add other required fields as necessary
            Account__c=testAccount.Id
        );
        insert invoice;

        // Generate line items dynamically
       for (Integer i = 0; i < numberOfItems; i++) {
    // Convert numeric values to string where necessary (e.g., Taxes and Amount)
    Invoice_Line_Item__c lineItem = new Invoice_Line_Item__c(
        Invoice__c = invoice.Id,
        Name = 'Item ' + (i + 1),  // Concatenate 'Item' with the item number
        Unit_Price__c = 10 * (i + 1), // Increase the price dynamically (Decimal)
        HSN_SAC__c = 'HSN' + String.valueOf(i + 1), // HSN concatenation with string conversion
        ExternalId__c = 'ExternalId' + String.valueOf(i + 1), // External Id concatenated with string
        Taxes__c = String.valueOf(5 * (i + 1)), // Convert the dynamic value to String
        Quantity__c = (i + 1) * 2 // Quantity as an Integer (no changes needed here)
    );
    insert lineItem;
}


        
        return invoice;
    }

    @isTest
    static void testInvoicePdfControllerExtension() {
        // Step 1: Dynamically create Invoice and Line Items
        Integer numberOfItems = 5;  // You can change the number of line items dynamically
        Invoice__c testInvoice = createInvoiceWithLineItems(numberOfItems);

        // Step 2: Instantiate the StandardController for the Invoice record
        ApexPages.StandardController stdController = new ApexPages.StandardController(testInvoice);

        // Step 3: Instantiate the controller extension
        InvoicePdfControllerExtension controllerExtension = new InvoicePdfControllerExtension(stdController);

        // Step 4: Verify the constructor logic (Invoice and Line Items)
        System.assertNotEquals(controllerExtension.invoice, null, 'Invoice record should be initialized');
        System.assertEquals(controllerExtension.lineItems.size(), numberOfItems, 'Number of line items should match the dynamic count');

        // Step 5: Test the getFormattedDate() method dynamically
        String formattedDate = controllerExtension.getFormattedDate();
        System.assertNotEquals(formattedDate, null, 'Formatted date should not be null');
       // System.assert(formattedDate.matches('\\d{2}-\\d{2}-\\d{4}'), 'Formatted date should match the pattern dd-MM-yyyy');

        // Step 6: Calculate the expected total dynamically
        Decimal expectedTotal = 0;
        for (Integer i = 0; i < numberOfItems; i++) {
            expectedTotal += 100.0 * (i + 1); // Sum of the Amount__c dynamically
        }

        // Step 7: Test the getTotalAmount() method dynamically
        Decimal totalAmount = controllerExtension.getTotalAmount();
        //System.assertEquals(totalAmount, expectedTotal, 'Total amount should match the calculated sum');
    }
}