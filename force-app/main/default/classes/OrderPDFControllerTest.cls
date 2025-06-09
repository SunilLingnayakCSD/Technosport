@isTest
private class OrderPDFControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create Account with billing and shipping
        Account acc = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Billing St',
            BillingCity = 'Billtown',
            BillingState = 'CA',
            BillingPostalCode = '90210',
            BillingCountry = 'USA',
            ShippingStreet = '456 Shipping Ave',
            ShippingCity = 'Shipville',
            ShippingState = 'CA',
            ShippingPostalCode = '90211',
            ShippingCountry = 'USA'
        );
        insert acc;

        // Create Retailer Account (for Retailer_Account__r lookup)
        Account retailerAcc = new Account(Name = 'Retailer Inc',BillingPostalCode='577345',Phone='9999000011');
        insert retailerAcc;

        // Create Visit
        Visit visit = new Visit(
            AccountId = acc.Id,
            PlaceId = null,
            PlannedVisitStartTime = System.now().addMinutes(-30),
            PlannedVisitEndTime = System.now()
        );
        insert visit;


 // Create a test product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;

// Create a test pricebook
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

// Create a test pricebook entry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbe;
        
        // Create Order linked to Visit
        Order ord = new Order(
           Pricebook2Id = standardPricebook.Id,
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Visit__c = visit.Id,
            Retailer_Account__c = retailerAcc.Id,
            PoDate = Date.today()
        );
        insert ord;

        // Create OrderItem
        OrderItem oi = new OrderItem(
            OrderId = ord.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 2,
            UnitPrice = 100 
        );
        insert oi;
    }

    @isTest
    static void testGetInvoiceJSON_Success() {
        Visit visit = [SELECT Id FROM Visit LIMIT 1];

        Test.startTest();
        Map<String, Object> invoice = OrderPDFController.getInvoiceJSON(visit.Id);
        Test.stopTest();

        System.assert(invoice != null, 'Invoice map should not be null');
        System.assert(invoice.containsKey('invoiceDate'), 'Should contain invoiceDate');
        System.assert(invoice.containsKey('order'), 'Should contain order');
        System.assert(invoice.containsKey('items'), 'Should contain items');
        System.assert(invoice.containsKey('billTo'), 'Should contain billTo');
        System.assert(invoice.containsKey('shipTo'), 'Should contain shipTo');

        // Check items list is not empty
        List<Object> items = (List<Object>) invoice.get('items');
        System.assert(items.size() > 0, 'Items list should not be empty');
    }

    @isTest
    static void testGetInvoiceJSON_NullVisitId() {
        try {
            Test.startTest();
            OrderPDFController.getInvoiceJSON(null);
            Test.stopTest();
            System.assert(false, 'Exception should have been thrown for null visitId');
        } catch (Exception e) {
            // Expecting some exception (commented out in original code, but recommended to check)
        }
    }

    @isTest
    static void testSavePdfToVisit_Success() {
        Visit visit = [SELECT Id FROM Visit LIMIT 1];

        // Dummy base64 PDF string (minimal valid base64 of PDF header)
        String base64Pdf = EncodingUtil.base64Encode(Blob.valueOf('%PDF-1.4'));

        Test.startTest();
        OrderPDFController.savePdfToVisit(visit.Id, base64Pdf, 'test.pdf');
        Test.stopTest();

        List<Attachment> atts = [SELECT Id, Name, ParentId FROM Attachment WHERE ParentId = :visit.Id];
        System.assert(atts.size() > 0, 'Attachment should be created');
        System.assertEquals('test.pdf', atts[0].Name, 'Attachment name should match');
    }

    @isTest
    static void testSavePdfToVisit_MissingData() {
        Visit visit = [SELECT Id FROM Visit LIMIT 1];
        try {
            Test.startTest();
            OrderPDFController.savePdfToVisit(null, null, null);
            Test.stopTest();
            System.assert(false, 'Exception should have been thrown for missing data');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Missing data or visit ID'), 'Correct exception message');
        }
    }

    @isTest
    static void testSavePdfAttachment_Success() {
        Visit visit = [SELECT Id FROM Visit LIMIT 1];
        String base64Pdf = 'data:application/pdf;base64,' + EncodingUtil.base64Encode(Blob.valueOf('%PDF-1.4'));

        Test.startTest();
        Id attId = OrderPDFController.savePdfAttachment(visit.Id, 'invoice.pdf', base64Pdf);
        Test.stopTest();

        Attachment att = [SELECT Id, Name FROM Attachment WHERE Id = :attId];
        System.assertEquals('invoice.pdf', att.Name, 'Attachment name should match');
    }

    @isTest
    static void testSavePdfAttachment_MissingData() {
        try {
            Test.startTest();
            OrderPDFController.savePdfAttachment(null, null, null);
            Test.stopTest();
            System.assert(false, 'Exception should be thrown for missing data');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Missing data for PDF save'), 'Correct exception message');
        }
    }

    @isTest
    static void testConstructor_NoVisitId() {
        Test.startTest();
        try {
            // This uses ApexPages.currentPage(), so set no param => should throw
            OrderPDFController ctrl = new OrderPDFController();
            System.assert(false, 'Expected exception due to missing visitId');
        } catch (AuraHandledException e) {
           // System.assert(e.getMessage().contains('Visit Id missing'));
        }
        Test.stopTest();
    }

    @isTest
    static void testConstructor_WithVisitId() {
        Visit visit = [SELECT Id FROM Visit LIMIT 1];
        Test.startTest();
        OrderPDFController ctrl = new OrderPDFController(visit.Id);
        Test.stopTest();

        System.assert(ctrl.order != null, 'Order should be queried');
        System.assert(ctrl.items != null && ctrl.items.size() > 0, 'Items should be built');
        System.assert(ctrl.billTo != null, 'Billing address should be built');
        System.assert(ctrl.shipTo != null, 'Shipping address should be built');
    }
}