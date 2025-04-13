@isTest
public class InvoicePdfControllerTest {
    
    @isTest
    public static void testInvoicePdfController() {
        
        // Step 1: Create test Account__c record (required for Invoice__c)
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
        
        // Step 2: Create test data for Invoice__c with Account__c reference
        Invoice__c testInvoice = new Invoice__c(
            Name = 'Test Invoice',
            Account__c = testAccount.Id,  // ✅ Added Account__c
            Invoice_Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(30),
            Delivery_Date__c = Date.today().addDays(10),
            Source__c = 'Test Source',
            Reference__c = 'Test Reference',
            E_Way_Bill_No__c = 'EWB123456'
        );
        insert testInvoice;

        // Step 3: Create test line items for the invoice
        Invoice_Line_Item__c testItem1 = new Invoice_Line_Item__c(
            Invoice__c = testInvoice.Id,
            Description__c = 'Test Item 1',
            HSN_SAC__c = '1234',
            Quantity__c = 2,
            Unit_Price__c = 50.0,
            Taxes__c = '10.0'
        );
        insert testItem1;
        
        Invoice_Line_Item__c testItem2 = new Invoice_Line_Item__c(
            Invoice__c = testInvoice.Id,
            Description__c = 'Test Item 2',
            HSN_SAC__c = '5678',
            Quantity__c = 1,
            Unit_Price__c = 100.0,
            Taxes__c = '20.0'
        );
        insert testItem2;
        
        // Step 4: Simulate the ApexPage URL with the test Invoice ID
        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', testInvoice.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(testInvoice);
        
        // Step 5: Instantiate the controller
        InvoicePdfController controller = new InvoicePdfController(sc);
        
        // Step 6: Perform assertions to verify if the fields are populated correctly
        System.assertEquals('Test Invoice', controller.name);
        System.assertEquals(Date.today().format(), controller.invoiceDate);
        System.assertEquals(Date.today().addDays(30).format(), controller.dueDate);
        System.assertEquals(Date.today().addDays(10).format(), controller.deliveryDate);
        System.assertEquals('Test Source', controller.source);
        System.assertEquals('Test Reference', controller.reference);
        System.assertEquals('EWB123456', controller.ewayBillNo);
        
        // Assert that the invoice items are correctly populated
        System.assertEquals(2, controller.invoiceItems.size());
        System.assertEquals('Test Item 1', controller.invoiceItems[0].Description__c);
        System.assertEquals('1234', controller.invoiceItems[0].HSN_SAC__c);
        System.assertEquals(2, controller.invoiceItems[0].Quantity__c);
        System.assertEquals(50.0, controller.invoiceItems[0].Unit_Price__c);
        
        System.assertEquals('Test Item 2', controller.invoiceItems[1].Description__c);
        System.assertEquals('5678', controller.invoiceItems[1].HSN_SAC__c);
        System.assertEquals(1, controller.invoiceItems[1].Quantity__c);
        System.assertEquals(100.0, controller.invoiceItems[1].Unit_Price__c);
        
        Test.stopTest();
    }
}