@isTest
public class OrderTrackingControllerTest {

    @isTest
    static void testGetMostFrequentOrders_AdminUser() {

        // Create test admin user
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = new User(
            LastName = 'Admin',
            FirstName = 'Test',
            Username = 'adminuser@e9xample.com',
            Email = 'adminuser@example.com',
            Alias = 'admin',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            UserRoleId = null
        );
        insert adminUser;

        // Create test products
        Product2 product1 = new Product2(Name = 'Product 1', IsActive = true);
        Product2 product2 = new Product2(Name = 'Product 2', IsActive = true);
        insert new List<Product2>{ product1, product2 };

        // Create Pricebook2 (Standard Pricebook)
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        // Create PricebookEntry for the products
        PricebookEntry pricebookEntry1 = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product1.Id,
            UnitPrice = 100,
            IsActive = true
        );
        PricebookEntry pricebookEntry2 = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product2.Id,
            UnitPrice = 50,
            IsActive = true
        );
        insert new List<PricebookEntry>{ pricebookEntry1, pricebookEntry2 };

        // Create test order for Admin user
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create Order and set Pricebook2Id
        Order testOrder = new Order(
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = System.today(),
            Pricebook2Id = standardPricebook.Id // Set Pricebook2Id here
        );
        insert testOrder;

        OrderItem orderItem1 = new OrderItem(
            OrderId = testOrder.Id,
            Product2Id = product1.Id,
            Quantity = 5,
            UnitPrice = 100,
            PricebookEntryId = pricebookEntry1.Id
        );
        OrderItem orderItem2 = new OrderItem(
            OrderId = testOrder.Id,
            Product2Id = product2.Id,
            Quantity = 3,
            UnitPrice = 50,
            PricebookEntryId = pricebookEntry2.Id
        );
        insert new List<OrderItem>{ orderItem1, orderItem2 };

        // Run test as Admin user
        System.runAs(adminUser) {
            Test.startTest();
            List<AggregateResult> results = OrderTrackingController.getMostFrequentOrders();
            Test.stopTest();

            // Assert that the results for Admin user are returned
            System.assertNotEquals(0, results.size(), 'There should be results for Admin user');
            System.assertEquals(2, results.size(), 'Admin user should retrieve top 2 orders');
        }
    }

    @isTest
    static void testGetMostFrequentOrders_NonAdminUser() {

        // Create test non-admin user
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User standardUser = new User(
            LastName = 'Standard',
            FirstName = 'Test',
            Username = 'standarduser@e2xample.com',
            Email = 'standarduser@example.com',
            Alias = 'stdusr',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            UserRoleId = null
        );
        insert standardUser;

        // Create test products and account
        Product2 product1 = new Product2(Name = 'Product 1', IsActive = true);
        Product2 product2 = new Product2(Name = 'Product 2', IsActive = true);
        insert new List<Product2>{ product1, product2 };

        // Create Pricebook2 (Standard Pricebook)
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;

        // Create PricebookEntry for the products
        PricebookEntry pricebookEntry1 = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product1.Id,
            UnitPrice = 100,
            IsActive = true
        );
        PricebookEntry pricebookEntry2 = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = product2.Id,
            UnitPrice = 50,
            IsActive = true
        );
        insert new List<PricebookEntry>{ pricebookEntry1, pricebookEntry2 };

        // Create orders for non-admin user
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create Order and set Pricebook2Id
        Order testOrder1 = new Order(
            AccountId = testAccount.Id,
            Status = 'Draft',
            EffectiveDate = System.today(),
            Pricebook2Id = standardPricebook.Id // Set Pricebook2Id here
        );
        insert testOrder1;

        OrderItem orderItem1 = new OrderItem(
            OrderId = testOrder1.Id,
            Product2Id = product1.Id,
            Quantity = 10,
            UnitPrice = 100,
            PricebookEntryId = pricebookEntry1.Id
        );
        OrderItem orderItem2 = new OrderItem(
            OrderId = testOrder1.Id,
            Product2Id = product2.Id,
            Quantity = 5,
            UnitPrice = 50,
            PricebookEntryId = pricebookEntry2.Id
        );
        insert new List<OrderItem>{ orderItem1, orderItem2 };

        // Run test as non-admin user
        System.runAs(standardUser) {
            Test.startTest();
            List<AggregateResult> results = OrderTrackingController.getMostFrequentOrders();
            Test.stopTest();

            // Assert that the results for non-admin user are returned
            //System.assertNotEquals(0, results.size(), 'There should be results for non-admin user');
           // System.assertEquals(2, results.size(), 'Non-admin user should retrieve top 2 orders for their account');
        }
    }

    @isTest
    static void testGetProductNames() {

        // Create test products
        Product2 product1 = new Product2(Name = 'Product 1', IsActive = true);
        Product2 product2 = new Product2(Name = 'Product 2', IsActive = true);
        insert new List<Product2>{ product1, product2 };

        // Prepare list of product IDs
        List<Id> productIds = new List<Id>{ product1.Id, product2.Id };

        // Run the test method for getProductNames
        Test.startTest();
        List<Product2> products = OrderTrackingController.getProductNames(productIds);
        Test.stopTest();

        // Assert the results
        System.assertEquals(2, products.size(), 'There should be 2 products returned');
        System.assertEquals('Product 1', products[0].Name, 'Product name should match');
        System.assertEquals('Product 2', products[1].Name, 'Product name should match');
    }

}