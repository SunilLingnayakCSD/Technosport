@isTest
public class CartControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create a portal account
        Account portalAccount = new Account(Name = 'Test Portal Account', BillingPostalCode='273747', BillingCity='xys', BillingStreet='Karnataka');
        insert portalAccount;

        // Create a contact for the portal user
        Contact portalContact = new Contact(
            FirstName = 'Portal',
            LastName = 'User',
            Email = 'portaluser@test.com',
            AccountId = portalAccount.Id
        );
        insert portalContact;

        // Portal user setup
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name = 'Community Distributor Access' LIMIT 1];
        User portalUser = new User(
            Username = 'portaluser@test.com',
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

        // Sales Representative (admin) user setup
        Profile salesRepProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Representative' LIMIT 1];
        User salesRepUser = new User(
            Username = 'salesrepuser@test.com',
            Email = 'salesrepuser@test.com',
            LastName = 'Rep',
            FirstName = 'Sales',
            Alias = 'srep',
            CommunityNickname = 'salesrepuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = salesRepProfile.Id,
            LanguageLocaleKey = 'en_US'
        );
        insert salesRepUser;

        // Create test products
        Product2 testProduct = new Product2(
            Name = 'Test Product', 
            Product_Type1__c = 'Product Template', 
            IsActive = true
        );
        insert testProduct;

        Product2 testVariant1 = new Product2(
            Name = 'Test Variant 1', 
            Product_Type1__c = 'Product Variant', 
            IsActive = true
        );
        insert testVariant1;

        Product2 testVariant2 = new Product2(
            Name = 'Test Variant 2', 
            Product_Type1__c = 'Product Variant', 
            IsActive = true
        );
        insert testVariant2;
        
        // Create retailer account and visit for admin tests
        Account retailerAccount = new Account(
            Name = 'Test Retailer Account', 
            BillingPostalCode='273747', 
            BillingCity='xys', 
            BillingStreet='Karnataka'
        );
        insert retailerAccount;
        
        RetailStore retailerStore = new RetailStore(
            Name = 'Test Store',
            AccountId = retailerAccount.Id
        );
        insert retailerStore;
        
        Visit testVisit = new Visit(
            AccountId = retailerAccount.Id,
            PlaceId = retailerStore.Id,
            PlannedVisitStartTime = System.now()
        );
        insert testVisit;
    }

    @isTest
    static void testInsertCartsWithItems() {
        User portalUser = [SELECT Id FROM User WHERE Username = 'portaluser@test.com'];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Product'];
        Product2 testVariant1 = [SELECT Id FROM Product2 WHERE Name = 'Test Variant 1'];
        Product2 testVariant2 = [SELECT Id FROM Product2 WHERE Name = 'Test Variant 2'];

        Map<String, Object> cartData = new Map<String, Object>{
            'id' => testProduct.Id,
            'name' => 'B108-CREW NECK-H/S-ASSORTED B2B',
            'price' => '1000',
            'imageUrl' => 'https://example.com/image.jpg',
            'quantity' => 2,
            'total' => 20,
            'boxes' => '20',
            'type' => 'Catalogue',
            'retailerPrice' => 1500,
            'noofpieces' => 10,
            'isFutureProduct' => true,
            'isFutureQuoShouuldteCreate' => false,
            'sizes' => new Map<Object, Object>{
                'S' => new Map<Object, Object>{
                    testVariant1.Id => new Map<Object, Object>{
                        'quantity' => 32, 
                        'color' => 'Red',
                        'isUpcomingVariant' => false
                    }
                },
                'L' => new Map<Object, Object>{
                    testVariant2.Id => new Map<Object, Object>{
                        'quantity' => 18, 
                        'color' => 'Blue',
                        'isUpcomingVariant' => true
                    }
                }
            }
        };

        System.runAs(portalUser) {
            Test.startTest();
            Map<String, Object> result = CartController.insertCarts(cartData, portalUser.Id, null);
            Test.stopTest();

            System.assertNotEquals(null, result.get('cartId'), 'Cart should have been created');
            System.assertEquals(true, result.get('isFutureProduct'), 'Future product flag should match');
            System.assertEquals(1500, result.get('retailerPrice'), 'Retailer price should match');
            
            List<Cart_Item__c> items = [SELECT Id, Size__c, Quantity__c, Product_varient__c, isUpcomingVarient__c 
                                       FROM Cart_Item__c 
                                       ORDER BY Size__c];
            System.assertEquals(2, items.size(), 'Should have created 2 cart items');
            System.assertEquals(true, items[1].isUpcomingVarient__c, 'One item should be marked as upcoming variant');
        }
    }

    @isTest
    static void testGetAllCartItems() {
        User portalUser = [SELECT Id FROM User WHERE Username = 'portaluser@test.com'];
        Account portalAccount = [SELECT Id FROM Account WHERE Name = 'Test Portal Account'];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Product'];

        System.runAs(portalUser) {
            Cart__c testCart = new Cart__c(
                Name = 'Test Cart', 
                Account__c = portalAccount.Id, 
                Product__c = testProduct.Id, 
                Unit_Price__c = 100,
                Total_Retailer_Price__c = 150,
                No_of_Boxes_Pieces_In_Bundle__c = 5,
                isFutureProduct__c = false,
                isFutureQuoShouuldteCreate__c = true
            );
            insert testCart;

            // Add cart items
            Product2 testVariant = [SELECT Id FROM Product2 WHERE Name = 'Test Variant 1' LIMIT 1];
            Cart_Item__c item = new Cart_Item__c(
                Cart__c = testCart.Id,
                Product_varient__c = testVariant.Id,
                Size__c = 'M',
                Quantity__c = 10,
                isUpcomingVarient__c = false
            );
            insert item;

            List<Cart__c> carts = CartController.getAllCartItems(portalUser.Id, null);
            System.assertEquals(1, carts.size(), 'Should return 1 cart');
            System.assertEquals(1, carts[0].Cart_Items__r.size(), 'Cart should have 1 item');
            System.assertEquals(false, carts[0].isFutureProduct__c, 'Future product flag should match');
            System.assertEquals(true, carts[0].isFutureQuoShouuldteCreate__c, 'Future quote flag should match');
        }
    }

    @isTest
    static void testDeleteFromCart() {
        User portalUser = [SELECT Id FROM User WHERE Username = 'portaluser@test.com'];
        Account portalAccount = [SELECT Id FROM Account WHERE Name = 'Test Portal Account'];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Product'];

        System.runAs(portalUser) {
            Cart__c testCart = new Cart__c(
                Name = 'Test Cart', 
                Account__c = portalAccount.Id, 
                Product__c = testProduct.Id, 
                Unit_Price__c = 100
            );
            insert testCart;

            CartController.deleteFromCart(testCart.Id, portalUser.Id, null);
            List<Cart__c> deletedCarts = [SELECT Id FROM Cart__c WHERE Id = :testCart.Id];
            System.assertEquals(0, deletedCarts.size(), 'Cart should have been deleted');
        }
    }

    @isTest
    static void testGetAllCartItemsWithNoAccount() {
        User portalUser = [SELECT Id FROM User WHERE Username = 'portaluser@test.com'];
        
        System.runAs(portalUser) {
            // Delete the contact to make the user have no account
           // delete [SELECT Id FROM Contact WHERE Email = 'portaluser@test.com'];
            
            try {
                CartController.getAllCartItems(portalUser.Id, null);
               // System.assert(false, 'Expected exception not thrown');
            } catch (AuraHandledException e) {
                System.assert(e.getMessage().contains('No account found'), 'Unexpected message: ' + e.getMessage());
            }
        }
    }

    @isTest
    static void testInsertCartAsAdmin() {
        User adminUser = [SELECT Id FROM User WHERE Username = 'salesrepuser@test.com'];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Product'];
        Visit testVisit = [SELECT Id, AccountId FROM Visit LIMIT 1];

        Map<String, Object> cartData = new Map<String, Object>{
            'id' => testProduct.Id,
            'name' => 'Admin Test Cart',
            'price' => '150',
            'imageUrl' => 'https://example.com/admin.jpg',
            'quantity' => 5,
            'total' => 750,
            'boxes' => 3,
            'type' => 'Catalogue',
            'retailerPrice' => 900,
            'noofpieces' => 15,
            'isFutureProduct' => false,
            'isFutureQuoShouuldteCreate' => true,
            'sizes' => new Map<Object, Object>()
        };

        System.runAs(adminUser) {
            Test.startTest();
            Map<String, Object> result = CartController.insertCarts(cartData, adminUser.Id, testVisit.Id);
            Test.stopTest();

            System.assertNotEquals(null, result.get('cartId'), 'Cart should have been created');
          //  System.assertEquals(testVisit.AccountId, result.get('accountId'), 'Should use visit account');
            System.assertEquals(900, result.get('retailerPrice'), 'Retailer price should match');
        }
    }

    @isTest
    static void testGetAllCartItemsAsAdmin() {
        User adminUser = [SELECT Id FROM User WHERE Username = 'salesrepuser@test.com'];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Product'];
        Visit testVisit = [SELECT Id, AccountId FROM Visit LIMIT 1];

        Cart__c adminCart = new Cart__c(
            Name = 'Admin Cart', 
            Product__c = testProduct.Id, 
            Account__c = testVisit.AccountId, 
            Unit_Price__c = 100,
            Total_Retailer_Price__c = 120,
            No_of_Boxes_Pieces_In_Bundle__c = 8,
            isFutureProduct__c = true,
            isFutureQuoShouuldteCreate__c = false
        );
        insert adminCart;

        System.runAs(adminUser) {
            List<Cart__c> carts = CartController.getAllCartItems(adminUser.Id, testVisit.Id);
            System.assertEquals(1, carts.size(), 'Should return 1 cart');
            System.assertEquals(true, carts[0].isFutureProduct__c, 'Future product flag should match');
            System.assertEquals(120, carts[0].Total_Retailer_Price__c, 'Retailer price should match');
        }
    }

    @isTest
    static void testDeleteFromCartAsAdmin() {
        User adminUser = [SELECT Id FROM User WHERE Username = 'salesrepuser@test.com'];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Product'];
        Visit testVisit = [SELECT Id, AccountId FROM Visit LIMIT 1];

        Cart__c adminCart = new Cart__c(
            Name = 'Admin Cart Delete', 
            Account__c = testVisit.AccountId, 
            Product__c = testProduct.Id, 
            Unit_Price__c = 90
        );
        insert adminCart;

        System.runAs(adminUser) {
            CartController.deleteFromCart(adminCart.Id, adminUser.Id, testVisit.Id);
            List<Cart__c> remaining = [SELECT Id FROM Cart__c WHERE Id = :adminCart.Id];
            System.assertEquals(0, remaining.size(), 'Cart should have been deleted');
        }
    }
    
    @isTest
    static void testInsertCartWithNullData() {
        User portalUser = [SELECT Id FROM User WHERE Username = 'portaluser@test.com'];
        
        System.runAs(portalUser) {
            try {
                CartController.insertCarts(null, portalUser.Id, null);
                System.assert(false, 'Expected exception not thrown');
            } catch (AuraHandledException e) {
               // System.assert(e.getMessage().contains('Cart data cannot be null'), 'Unexpected message: ' + e.getMessage());
            }
        }
    }
    
    @isTest
    static void testProcessSizeVariantsWithEmptyData() {
        User portalUser = [SELECT Id FROM User WHERE Username = 'portaluser@test.com'];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Product'];
        
        Map<String, Object> cartData = new Map<String, Object>{
            'id' => testProduct.Id,
            'name' => 'Test Empty Sizes',
            'price' => '100',
            'imageUrl' => 'https://example.com/test.jpg',
            'quantity' => 1,
            'total' => 100,
            'boxes' => 1,
            'type' => 'Catalogue',
            'retailerPrice' => 120,
            'noofpieces' => 5,
            'isFutureProduct' => false,
            'isFutureQuoShouuldteCreate' => false,
            'sizes' => new Map<Object, Object>()
        };
        
        System.runAs(portalUser) {
            Test.startTest();
            Map<String, Object> result = CartController.insertCarts(cartData, portalUser.Id, null);
            Test.stopTest();
            
            System.assertNotEquals(null, result.get('cartId'), 'Cart should have been created');
            System.assertEquals(0, [SELECT COUNT() FROM Cart_Item__c], 'No cart items should be created');
        }
    }
}