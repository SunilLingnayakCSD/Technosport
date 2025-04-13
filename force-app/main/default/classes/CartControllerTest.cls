@isTest
public class CartControllerTest {

    @TestSetup
    static void setupTestData() {
        // Create a portal account
        Account portalAccount = new Account(Name = 'Test Portal Account');
        insert portalAccount;

        // Create a contact for the portal user
        Contact portalContact = new Contact(
            FirstName = 'Portal',
            LastName = 'User',
            Email = 'portaluser@test.com',
            AccountId = portalAccount.Id
        );
        insert portalContact;

        // Create a portal user
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
    }

   @isTest
    static void testInsertCartsWithItems() {
        // Get the test user
        User portalUser = [SELECT Id FROM User WHERE Username = 'portaluser@test.com'];

        // Get the test product and variants
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Product'];
        Product2 testVariant1 = [SELECT Id FROM Product2 WHERE Name = 'Test Variant 1'];
        Product2 testVariant2 = [SELECT Id FROM Product2 WHERE Name = 'Test Variant 2'];

        // Create the data in the expected format
        Map<String, Object> cartData = new Map<String, Object>{
            'id' => testProduct.Id,
            'name' => 'B108-CREW NECK-H/S-ASSORTED B2B',
            'price' => '1000',
            'imageUrl' => 'https://example.com/image.jpg',
            'quantity' => 2,
            'total' => 20,
            'boxes' => '20',
            'type' => 'Catalogue',
            'sizes' =>  new Map<Object, Object>{
                'S' =>  new Map<Object, Object>{
                    testVariant1.Id => new Map<Object, Object>{
                        'quantity' => 32,
                        'color' => ''
                    }
                },
                'L' =>  new Map<Object, Object>{
                    testVariant2.Id => new Map<Object, Object>{
                        'quantity' => 18,
                        'color' => ''
                    }
                }
            },
            'pricebookEntryId' => '01uC4000000XFI1IAO'
        };

        // Run the test as the test user
        System.runAs(portalUser) {
            Test.startTest();
            Map<String, Object> result = CartController.insertCarts(cartData, portalUser.Id);
            Test.stopTest();

            // Verify cart
            System.assertNotEquals(null, result.get('cartId'));
            System.assertEquals(testProduct.Id, result.get('id'));

            // Verify cart items
            List<Cart_Item__c> items = [SELECT Id, Size__c, Color__c, Quantity__c, Product_varient__c FROM Cart_Item__c];
            System.assertEquals(2, items.size());
            System.assertEquals('S', items[0].Size__c);
            System.assertEquals('L', items[1].Size__c);
            System.assertEquals(32, items[0].Quantity__c);
            System.assertEquals(18, items[1].Quantity__c);
            System.assertEquals(testVariant1.Id, items[0].Product_varient__c);
            System.assertEquals(testVariant2.Id, items[1].Product_varient__c);
        }
    }


    // Test 2: Insert cart with empty sizes
    @isTest
    static void testInsertCartsWithEmptySizes() {
        User portalUser = [SELECT Id FROM User WHERE Username = 'portaluser@test.com'];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Product'];

        System.runAs(portalUser) {
            Map<String, Object> cartData = new Map<String, Object>{
                'id' => testProduct.Id,
                'name' => 'Test Cart',
                'price' => '100',
                'imageUrl' => 'http://example.com/image.jpg',
                'quantity' => 0,
                'total' => 0,
                'boxes' => '0',
                'type' => 'Test Type',
                'sizes' => new Map<Object, Object>() // Empty sizes
            };

            Map<String, Object> result = CartController.insertCarts(cartData, portalUser.Id);
           // System.assertNotEquals(null, result.get('cartId'));

            // No cart items should be created
            List<Cart_Item__c> items = [SELECT Id FROM Cart_Item__c];
            System.assertEquals(0, items.size());
        }
    }
    // Test 4: Get all cart items
    @isTest
    static void testGetAllCartItems() {
        User portalUser = [SELECT Id FROM User WHERE Username = 'portaluser@test.com'];
        Account portalAccount = [SELECT Id FROM Account WHERE Name = 'Test Portal Account'];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Product'];

        System.runAs(portalUser) {
            // Create test cart
            Cart__c testCart = new Cart__c(
                Name = 'Test Cart',
                Account__c = portalAccount.Id,
                Product__c = testProduct.Id,
                Unit_Price__c = 100
            );
            insert testCart;

            List<Cart__c> carts = CartController.getAllCartItems(portalUser.Id);
            System.assertEquals(1, carts.size());
        }
    }

    // Test 5: Delete cart
    @isTest
    static void testDeleteFromCart() {
        User portalUser = [SELECT Id FROM User WHERE Username = 'portaluser@test.com'];
        Account portalAccount = [SELECT Id FROM Account WHERE Name = 'Test Portal Account'];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Product'];

        System.runAs(portalUser) {
            // Create test cart
            Cart__c testCart = new Cart__c(
                Name = 'Test Cart',
                Account__c = portalAccount.Id,
                Product__c = testProduct.Id,
                Unit_Price__c = 100
            );
            insert testCart;

            CartController.deleteFromCart(testCart.Id, portalUser.Id);
            List<Cart__c> deletedCarts = [SELECT Id FROM Cart__c WHERE Id = :testCart.Id];
            System.assertEquals(0, deletedCarts.size());
        }
    }

    // Test 6: Get all cart items with no account
    @isTest
    static void testGetAllCartItemsWithNoAccount() {
        try {
            CartController.getAllCartItems('invalidRecordId');
            System.assert(false, 'Expected exception not thrown');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('No account found'), 'Unexpected error: ' + e.getMessage());
        }
    }

    // Test 7: Delete cart with invalid account
    @isTest
    static void testDeleteFromCartWithInvalidAccount() {
        User portalUser = [SELECT Id FROM User WHERE Username = 'portaluser@test.com'];
        Account portalAccount = [SELECT Id FROM Account WHERE Name = 'Test Portal Account'];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Name = 'Test Product'];

        System.runAs(portalUser) {
            // Create test cart
            Cart__c testCart = new Cart__c(
                Name = 'Test Cart',
                Account__c = portalAccount.Id,
                Product__c = testProduct.Id,
                Unit_Price__c = 100
            );
            insert testCart;

            try {
                CartController.deleteFromCart(testCart.Id, 'invalidRecordId');
                System.assert(false, 'Expected exception not thrown');
            } catch (AuraHandledException e) {
                //System.assert(e.getMessage().contains('No account found'), 'Unexpected error: ' + e.getMessage());
            }

            // Verify cart is not deleted
            List<Cart__c> carts = [SELECT Id FROM Cart__c WHERE Id = :testCart.Id];
            System.assertEquals(1, carts.size(), 'Cart should not be deleted');
        }
    }
}