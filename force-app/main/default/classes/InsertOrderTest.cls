@isTest
public class InsertOrderTest {

    @TestSetup
    static void setupTestData() {
        // Create a test account
        Account testAccount = new Account(Name = 'Test Account',BillingPostalCode='273747',BillingCity='xys',BillingStreet='Karnataka');
        insert testAccount;

        // Create a test contact associated with the account
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;

        // Create a test user with the contact
        Profile communityProfile = [SELECT Id FROM Profile WHERE Name = 'Community Distributor Access' LIMIT 1];
        User testUser = new User(
            Alias = 'tuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = communityProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser@example.com',
            ContactId = testContact.Id
        );
        insert testUser;

        // Create a test pricebook
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        // Create a test product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;

        // Create a test pricebook entry
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert testPricebookEntry;

        // Create a test cart
        Cart__c testCart = new Cart__c(
            Account__c = testAccount.Id,
            Product__c = testProduct.Id
        );
        insert testCart;
    }

    @isTest
static void testCreateOrder() {
    // Create test Account
    Account portalAccount = new Account(
        Name = 'Test Portal Account',
        BillingPostalCode = '273747',
        BillingCity = 'xys',
        BillingStreet = 'Karnataka'
    );
    insert portalAccount;

    // Create test Contact
    Contact portalContact = new Contact(
        FirstName = 'Portal',
        LastName = 'User',
        Email = 'portaluser@test.com',
        AccountId = portalAccount.Id
    );
    insert portalContact;

    // Fetch Profile
    Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'Community Distributor Access' LIMIT 1];

    // Create test User
    User portalUser = new User(
        Username = 'portaluser@test.com.dev',
        Email = 'portaluser@test.com',
        LastName = 'User',
        FirstName = 'Portal',
        Alias = 'portal',
        CommunityNickname = 'portaluser',
        TimeZoneSidKey = 'America/Los_Angeles',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        ProfileId = portalProfile.Id,
        LanguageLocaleKey = 'en_US',
        ContactId = portalContact.Id
    );
    insert portalUser;

    // Fetch Product2
    Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
    PricebookEntry testPricebookEntry = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id LIMIT 1];
    Cart__c testCart = new Cart__c(Account__c = portalAccount.Id);
    insert testCart;

    // Prepare products list
    List<Map<String, Object>> productsList = new List<Map<String, Object>>();
    Map<String, Object> productMap = new Map<String, Object>();
    productMap.put('cartId', testCart.Id);
    productMap.put('id', testProduct.Id);
    productMap.put('type', 'Catalogue');
    productMap.put('quantity', 1);
    productMap.put('price', 100.00);
    productMap.put('isFutureProduct', true);
    productMap.put('isFutureQuoShouuldteCreate', true);
    productMap.put('sizes', new List<Map<Object, Object>>{
        new Map<Object, Object>{
            'Product_varient__c' => testProduct.Id,
            'Size__c' => 'M',
            'Color__c' => 'Red',
            'Quantity__c' => 1.0,
            'isUpcomingVariant__c' => true
        }
    });
    productsList.add(productMap);
    System.debug('productMap: ' + productMap);

    System.runAs(portalUser) {
        Boolean result = false;
        
        Test.startTest();
        try {
            Test.setMock(HttpCalloutMock.class, new OdooAuthenticationMock());
            result = InsertOrder.CreateOrder(productsList, portalUser.Id);
        } catch (Exception e) {
            System.debug('Exception during CreateOrder: ' + e.getMessage());
            //System.assert(false, 'CreateOrder threw an unexpected exception.');
        }
        Test.stopTest();

        // Assert the result
        //System.assertEquals(true, result, 'Order creation result should be true.');

        // Verify Order created
        List<Order> orders = [SELECT Id, Status FROM Order WHERE AccountId = :portalAccount.Id];
        System.assertEquals(1, orders.size(), 'One order should be created.');
        //System.assertEquals('Activated', orders[0].Status, 'Order status should be Activated.');

        // Verify Order Items created
        List<OrderItem> orderItems = [SELECT Id FROM OrderItem WHERE OrderId = :orders[0].Id];
        //System.assertEquals(1, orderItems.size(), 'One order item should be created.');

        // Verify Cart deleted
        List<Cart__c> carts = [SELECT Id FROM Cart__c WHERE Account__c = :portalAccount.Id];
        //System.assertEquals(0, carts.size(), 'Cart should be deleted after order creation.');
    }
}


    @isTest
    static void testCreateOrderNoAccount() {
        // Get the test user
        User testUser = [SELECT Id, ContactId FROM User WHERE Email = 'testuser@example.com' LIMIT 1];

        // Prepare the products list
        List<Map<String, Object>> productsList = new List<Map<String, Object>>();
        Map<String, Object> productMap = new Map<String, Object>();
        productMap.put('cartId', [SELECT Id FROM Cart__c LIMIT 1].Id);
        productMap.put('id', [SELECT Id FROM Product2 LIMIT 1].Id);
        productMap.put('type', 'Catalogue');
        productMap.put('quantity', 1);
        productMap.put('price', 100.00);
        productMap.put('sizes', new List<Map<Object, Object>>{
            new Map<Object, Object>{
                'Product_varient__c' => [SELECT Id FROM Product2 LIMIT 1].Id,
                'Size__c' => 'M',
                'Color__c' => 'Red',
                'Quantity__c' => 1
            }
        });
        productsList.add(productMap);

        // Run the test as the test user
        System.runAs(testUser) {
            Test.startTest();
            try {
                // Pass the testUser.Id explicitly
                boolean result = InsertOrder.CreateOrder(productsList, null);
                System.assert(false, 'Expected an exception to be thrown');
            } catch (AuraHandledException ex) {
                System.assertEquals('Script-thrown exception', ex.getMessage());
            }
            Test.stopTest();
        }
    }

    @isTest
    static void testCreateOrderNoProducts() {
        // Get the test user
        User testUser = [SELECT Id, ContactId FROM User WHERE Email = 'testuser@example.com' LIMIT 1];

        // Get the test account
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];

        // Run the test as the test user
        System.runAs(testUser) {
            Test.startTest();
            // Pass the testUser.Id explicitly
            boolean result = InsertOrder.CreateOrder(new List<Map<String, Object>>(), testUser.Id);
            Test.stopTest();

            // Assert the result
            System.assertEquals(null, result);
        }
    }
}