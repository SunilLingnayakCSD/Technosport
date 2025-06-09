@isTest
public class InsertreatilerOrderTest {

    // Helper method to create a test user
    private static User createTestUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
	 User testUseradmin = new User(
            FirstName = 'Teswt',
            LastName = 'Usewr',
            Email = 'testuser@33example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US'
           
        );
        insert testUseradmin;
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@example.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            ManagerId =testUseradmin.Id
        );

        insert testUser;
        return testUser;
    }

    @isTest
    public static void testCreateOrder_Success() {
        User testUser = createTestUser();
        System.runAs(testUser) {

            RecordType rtd = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Distributor' LIMIT 1];
            RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Customer' LIMIT 1];
            Account distributorAccount = new Account(Name = 'Distributor Account', BillingPostalCode='273747',BillingCity='xys',BillingStreet='Karnataka',RecordTypeId=rtd.Id);
            insert distributorAccount;
            Account retailerAccount = new Account(Name = 'Retailer Account', BillingPostalCode='273747',BillingCity='xys',BillingStreet='Karnataka',RecordTypeId=rt.Id,Distributor__c=distributorAccount.Id);
            insert retailerAccount;

            
            
            Visit testVisit = new Visit(
                AccountId = retailerAccount.Id,
                PlannedVisitStartTime = System.now()
            );
            insert testVisit;

            Product2 product = new Product2(Name = 'Test Product', IsActive = true);
            insert product;

             Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
            PricebookEntry pricebookEntry = new PricebookEntry(
                Pricebook2Id = standardPricebook.Id,
                Product2Id = product.Id,
                UnitPrice = 100.00,
                IsActive = true
            );
            insert pricebookEntry;

            List<Map<String, Object>> productsList = new List<Map<String, Object>>();
            Map<String, Object> productData = new Map<String, Object>();
            productData.put('cartId', 'cart1');
            productData.put('id', product.Id);
            productData.put('type', 'Catalogue');
            productData.put('quantity', 10);

            List<Object> sizes = new List<Object>();
            Map<Object, Object> sizeData = new Map<Object, Object>();
            sizeData.put('Product_varient__c', product.Id);
            sizeData.put('Size__c', 'L');
            sizeData.put('Color__c', 'Red');
            sizeData.put('Quantity__c', 10);
            sizes.add(sizeData);
            productData.put('sizes', sizes);
            productData.put('price', 100.00);
            productsList.add(productData);
            try{
            Test.startTest();
            Boolean result = InsertreatilerOrder.CreateOrder(productsList, testUser.Id, testVisit.Id, distributorAccount.Id);
            Test.stopTest();
                 //System.assert(false, 'Exception should have been thrown due to missing distributor.');
            }catch(AuraHandledException e){
                 System.assertEquals('Script-thrown exception', e.getMessage());
            }
            List<Order> orders = [SELECT Id, AccountId, Status FROM Order WHERE AccountId = :retailerAccount.Id];
            System.assertNotEquals(0, orders.size(), 'Order should have been created.');
            System.assertEquals('Draft', orders[0].Status, 'The order status should be Draft.');

            List<OrderItem> orderItems = [SELECT Id, OrderId, Quantity, Product2Id FROM OrderItem WHERE OrderId = :orders[0].Id];
           // System.assertNotEquals(0, orderItems.size(), 'OrderItems should have been created.');
            //System.assertEquals(10, orderItems[0].Quantity, 'OrderItem quantity should match the product quantity.');
        }
    }

    @isTest
    public static void testCreateOrder_NoDistributor() {
        User testUser = createTestUser();
        System.runAs(testUser) {
			RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Customer' LIMIT 1];
            Account retailerAccount = new Account(Name = 'Retailer Account', BillingPostalCode='273747',BillingCity='xys',BillingStreet='Karnataka',RecordTypeId=rt.Id);
            insert retailerAccount;

            Visit testVisit = new Visit(
                AccountId = retailerAccount.Id,
                PlannedVisitStartTime = System.now()
            );
            insert testVisit;

            List<Map<String, Object>> productsList = new List<Map<String, Object>>();
            Map<String, Object> productData = new Map<String, Object>();
            productData.put('cartId', 'cart1');
            productData.put('id', 'someProductId'); 
            productData.put('type', 'Catalogue');
            productData.put('quantity', 10);
            productsList.add(productData);

            try {
                Test.startTest();
                InsertreatilerOrder.CreateOrder(productsList, 'recordId', testVisit.Id, null);
                Test.stopTest();
                System.assert(false, 'Exception should have been thrown due to missing distributor.');
            } catch (AuraHandledException e) {
                System.assertEquals('Script-thrown exception', e.getMessage());
            }
        }
    }
}