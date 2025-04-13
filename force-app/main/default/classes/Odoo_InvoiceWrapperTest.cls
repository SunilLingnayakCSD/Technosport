@isTest
private class Odoo_InvoiceWrapperTest {
    @isTest
    static void testInvoiceWrapper() {
        // Creating an instance of the Odoo_InvoiceWrapper class
        Odoo_InvoiceWrapper invoiceWrapper = new Odoo_InvoiceWrapper();
        
        // Setting values for the properties
        invoiceWrapper.invoice_date_due = '2025-12-31';
        invoiceWrapper.invoice_line_ids = new List<String>{'Line 1', 'Line 2'};
        invoiceWrapper.invoice_date = true;
        invoiceWrapper.journal_id = 1;
        invoiceWrapper.id = 123;
        invoiceWrapper.name = 'Invoice 123';
        invoiceWrapper.delivery_date = true;
        invoiceWrapper.partner_id = 456;
        invoiceWrapper.name_X = 'Invoice_X';
        invoiceWrapper.partner_shipping_id = true;
        invoiceWrapper.model = 'Invoice Model';
        
        // Asserting that the properties are correctly assigned
        System.assertEquals('2025-12-31', invoiceWrapper.invoice_date_due);
        System.assertEquals(new List<String>{'Line 1', 'Line 2'}, invoiceWrapper.invoice_line_ids);
        System.assertEquals(true, invoiceWrapper.invoice_date);
        System.assertEquals(1, invoiceWrapper.journal_id);
        System.assertEquals(123, invoiceWrapper.id);
        System.assertEquals('Invoice 123', invoiceWrapper.name);
        System.assertEquals(true, invoiceWrapper.delivery_date);
        System.assertEquals(456, invoiceWrapper.partner_id);
        System.assertEquals('Invoice_X', invoiceWrapper.name_X);
        System.assertEquals(true, invoiceWrapper.partner_shipping_id);
        System.assertEquals('Invoice Model', invoiceWrapper.model);
    }
}