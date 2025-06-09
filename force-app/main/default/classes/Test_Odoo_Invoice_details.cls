@isTest
private class Test_Odoo_Invoice_details {

    @isTest
    static void testHandleWebhook_successFlow() {
        // Set up test data
        Account testAccount = new Account(
            Name = 'Test Account',
            External_Id__c = 'EXT123',
            ShippingStreet = '123 Test St',
            ShippingCity = 'Testville',
            ShippingState = 'TS',
            ShippingPostalCode = '12345',
            ShippingCountry = 'USA',
            BillingPostalCode='273747',BillingCity='xys',BillingStreet='Karnataka'
        );
        insert testAccount;

        Product2 testProduct = new Product2(
            Name = 'Test Product',
            Variant_ExternalId__c = 'PROD123',
            IsActive = true
        );
        insert testProduct;

        Order testOrder = new Order(
            Name = 'Test Order',
            Status = 'Draft',
            EffectiveDate = Date.today(),
            AccountId = testAccount.Id
        );
        insert testOrder;

        Quote testQuote = new Quote(
            Name = 'Test Quote',
            OrderId__c = testOrder.Id,
            Status = 'Draft'
        );
        insert testQuote;

        // Create mock payload
        String base64Pdf = EncodingUtil.base64Encode(Blob.valueOf('Test PDF content'));

        Map<String, Object> payload = new Map<String, Object>{
            'name' => 'Test Invoice',
            'local_transporter' => 'Transport Co.',
            'lr_date' => String.valueOf(Date.today()),
            'lr_no' => 'LR123',
            'id' => 101,
            'partner_id' => 'EXT123',
            'invoice_date_due' => String.valueOf(Date.today().addDays(10)),
            'invoice_date' => String.valueOf(Date.today()),
            'partner_shipping_id' => null,
            'journal_id' => 'JRN001',
            'salesforce_id' => testQuote.Id,
            'amount_paid' => 100.0,
            'amount_total_words' => 'One Hundred',
            'ref' => 'INVREF001',
            'amount_residual' => 0.0,
            'delivery_address' => 'Deliver Here',
            'invoicePdf' => new Map<String, Object>{
                'base64' => base64Pdf,
                'fileName' => 'invoice.pdf'
            },
            'invoice_line_items' => new List<Object>{
                new Map<String, Object>{
                    'journalId' => 'JRN001',
                    'invoiceLineId' => 'INVLINE123',
                    'moveId' => 'MOVE001',
                    'name' => 'Product Line 1',
                    'priceUnit' => 50.0,
                    'productId' => 'PROD123',
                    'quantity' => 2
                }
            }
        };

        String jsonPayload = JSON.serialize(payload);

        // Set up the mock request and response
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonPayload);
        req.httpMethod = 'POST';
        req.requestURI = '/services/apexrest/odoo/invoicedetails/LineItems/';
        RestContext.request = req;
        RestResponse res = new RestResponse();
        RestContext.response = res;
Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());
        Test.startTest();
        Odoo_Invoice_details.handleWebhook();
        Test.stopTest();

        // Assert Invoice created
        List<Invoice__c> invoices = [SELECT Id, Name, Account__c FROM Invoice__c WHERE Name = 'Test Invoice'];
        System.assertEquals(1, invoices.size(), 'Invoice should be created');
        System.assertEquals(testAccount.Id, invoices[0].Account__c);

        // Assert Invoice Line Item
        List<Invoice_Line_Item__c> lineItems = [SELECT Id, Name FROM Invoice_Line_Item__c WHERE Invoice__c = :invoices[0].Id];
        System.assertEquals(1, lineItems.size(), 'One Invoice Line Item should be created');

        // Assert ContentDocumentLink
        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :invoices[0].Id];
        System.assertEquals(1, links.size(), 'PDF should be attached to the Invoice');

        // Assert Quote and Order updated
        Quote updatedQuote = [SELECT Status FROM Quote WHERE Id = :testQuote.Id];
       // System.assertEquals('Invoice', updatedQuote.Status);
        Order updatedOrder = [SELECT Status FROM Order WHERE Id = :testOrder.Id];
       // System.assertEquals('Invoice', updatedOrder.Status);
    }

    @isTest
    static void testHandleWebhook_missingInvoiceDateDue() {
        Map<String, Object> payload = new Map<String, Object>{
            'name' => 'Invalid Invoice',
            'id' => 999,
            'invoice_date' => String.valueOf(Date.today())
        };

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response = new RestResponse();
	Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());
        Test.startTest();
        Odoo_Invoice_details.handleWebhook();
        Test.stopTest();

        System.assertEquals(500, RestContext.response.statusCode, 'Should fail due to missing invoice_date_due');
        System.assert(RestContext.response.responseBody.toString().contains('Missing required field'), 'Error should mention invoice_date_due');
    }
}