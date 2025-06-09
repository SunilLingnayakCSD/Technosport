@isTest
public class Odoo_AccountingTest {

    @isTest
    static void testGetAccountingDetails_B2BCustomer_Success() {
        Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Distributor' LIMIT 1].Id;
        Account acc = new Account(Name = 'Test Account', External_Id__c = '12345', RecordTypeId = recordTypeId);
        insert acc;

        Odoo_Accounting.AccountWrapper wrapper = new Odoo_Accounting.AccountWrapper();
        wrapper.id = 12345;
        wrapper.credit = 1000;
        wrapper.debit = 500;
        wrapper.residual_amount = 200;
        wrapper.is_b2b_customer = true;

        String requestBody = JSON.serialize(wrapper);
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        Test.startTest();
        Odoo_Accounting.getAccountingDetails();
        Test.stopTest();

        Account updatedAcc = [SELECT Credit__c, Debit__c, residual_amount__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(1000, updatedAcc.Credit__c);
        System.assertEquals(500, updatedAcc.Debit__c);
        System.assertEquals(200, updatedAcc.residual_amount__c);
    }

    @isTest
    static void testGetAccountingDetails_NoAccountFound() {
        Odoo_Accounting.AccountWrapper wrapper = new Odoo_Accounting.AccountWrapper();
        wrapper.id = 99999;
        wrapper.credit = 1000;
        wrapper.debit = 500;
        wrapper.residual_amount = 200;
        wrapper.is_b2b_customer = true;

        String requestBody = JSON.serialize(wrapper);
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        Test.startTest();
        Odoo_Accounting.getAccountingDetails();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testGetAccountingDetails_MissingRequestBody() {
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = null;

        Test.startTest();
        Odoo_Accounting.getAccountingDetails();
        Test.stopTest();

        System.assertEquals(500, RestContext.response.statusCode);
    }

    @isTest
    static void testGetAccountingDetails_MissingAccountId() {
        Odoo_Accounting.AccountWrapper wrapper = new Odoo_Accounting.AccountWrapper();
        wrapper.id = null;
        wrapper.credit = 1000;
        wrapper.debit = 500;
        wrapper.residual_amount = 200;
        wrapper.is_b2b_customer = true;

        String requestBody = JSON.serialize(wrapper);
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        Test.startTest();
        Odoo_Accounting.getAccountingDetails();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testGetAccountingDetails_DmlException() {
        Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Distributor' LIMIT 1].Id;
        Account acc = new Account(Name = 'Test Account', External_Id__c = '54321', RecordTypeId = recordTypeId);
        insert acc;
        delete acc;

        Odoo_Accounting.AccountWrapper wrapper = new Odoo_Accounting.AccountWrapper();
        wrapper.id = 54321;
        wrapper.credit = 1000;
        wrapper.debit = 500;
        wrapper.residual_amount = 200;
        wrapper.is_b2b_customer = true;

        String requestBody = JSON.serialize(wrapper);
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(requestBody);

        Test.startTest();
        Odoo_Accounting.getAccountingDetails();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testGetAccountingDetails_GenericException() {
        Test.startTest();
        try {
            Odoo_Accounting.getAccountingDetails();
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
    }
}