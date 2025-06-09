@isTest
public class Test_Odoo_partnerledger_batch {

    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            // Construct mock response
            String mockBody = JSON.serialize(new Map<String, Object>{
                'jsonrpc' => '2.0',
                'id' => null,
                'result' => new List<Object>{
                    new Map<String, Object>{
                        'id' => 12345,
                        'move_id' => new List<Object>{'INV123', 'INV Description'},
                        'name' => 'Ledger Test Entry',
                        'partner_id' => new List<Object>{'78901', 'Test Partner'},
                        'account_id' => new List<Object>{49, 'Account Name'},
                        'invoice_date' => '2024-02-15',
                        'date_maturity' => '2024-02-15',
                        'amount_currency' => 100.50,
                        'matching_number' => 'MATCH001',
                        'debit' => 50.25,
                        'credit' => 25.00,
                        'balance' => 25.25
                    }
                }
            });

            res.setBody(mockBody);
            return res;
        }
    }

    @isTest
    static void testBatchExecutionWithInvoiceAndAccount() {
        // Setup test data
        Account acc = new Account(Name = 'Test Account', External_Id__c = '78901', BillingPostalCode = '273747', BillingCity = 'xys', BillingStreet = 'Karnataka');
        insert acc;

        Invoice__c inv = new Invoice__c(Name = 'Test Invoice', Invoice_Id__c = 'INV123', Account__c = acc.Id);
        insert inv;

        // Mock the HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        Odoo_partnerledger_batch batch = new Odoo_partnerledger_batch();
        Database.executeBatch(batch, 1);
        Test.stopTest();

        // Assert the ledger is created
        List<Partner_Ledger__c> ledgers = [SELECT Id, Name, Invoice__c, Account__c, ExternalId__c FROM Partner_Ledger__c];
        System.assertEquals(1, ledgers.size(), 'Ledger should be created');
        System.assertEquals(inv.Id, ledgers[0].Invoice__c, 'Invoice should be linked');
        System.assertEquals(acc.Id, ledgers[0].Account__c, 'Account should be linked');
    }

    @isTest
    static void testBatchExecutionWithoutInvoice() {
        // Create only Account, no Invoice
        Account acc = new Account(Name = 'Test Account', External_Id__c = '78901',BillingPostalCode='273747',BillingCity='xys',BillingStreet='Karnataka');
        insert acc;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        Odoo_partnerledger_batch batch = new Odoo_partnerledger_batch();
        Database.executeBatch(batch, 1);
        Test.stopTest();

        List<Partner_Ledger__c> ledgers = [SELECT Id, Invoice__c, Account__c FROM Partner_Ledger__c];
        System.assertEquals(1, ledgers.size(), 'Ledger should be created');
        System.assertEquals(null, ledgers[0].Invoice__c, 'Invoice should be null if not found');
        System.assertEquals(acc.Id, ledgers[0].Account__c, 'Account should still be linked');
    }
}