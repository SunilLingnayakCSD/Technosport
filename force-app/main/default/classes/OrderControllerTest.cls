@isTest
private class OrderControllerTest {
    @testSetup
    static void setupData() { 
        
          // Get standard pricebook ID without querying
        Id standardPbId = Test.getStandardPricebookId();

        // Create CUSTOM PRICEBOOKS (R1, R2, R3)
        List<Pricebook2> customPricebooks = new List<Pricebook2>{
            new Pricebook2(Name = 'R1 Customer Pricebook', IsActive = true),
            new Pricebook2(Name = 'R2 Customer Pricebook', IsActive = true),
            new Pricebook2(Name = 'R3 Customer Pricebook', IsActive = true)
        };
        insert customPricebooks;
        
        //Create a Product template with required field 
        cgcloud__Product_Template__c ProductTemplatetest= new cgcloud__Product_Template__c(
            Name ='Test Product template',
            cgcloud__Sales_Org__c='0001',
            cgcloud__Description_Language_1__c	='Test Product template',
            cgcloud__Active__c=true
            
            
        );
        insert ProductTemplatetest;
        
        
        // Create a product with required fields
        Id productRecTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Product').getRecordTypeId();
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true,
                        RecordTypeId = productRecTypeId,
            Product_Category__c = 'Men', // Ensure this matches getProducts filters
            cgcloud__Category__c = 'ALL', // Ensure this matches getProducts filters
            cgcloud__Product_Template__c=ProductTemplatetest.id,
            cgcloud__Product_Level__c='Product',
            cgcloud__Description_1_Language_1__c='Test Product'
        );
        insert testProduct;



       // Activate standard pricebook by creating a PricebookEntry
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPbId,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardPbe;

        // Create PricebookEntries for custom pricebooks
        List<PricebookEntry> customPbes = new List<PricebookEntry>();
        for (Pricebook2 pb : customPricebooks) {
            customPbes.add(
                new PricebookEntry(
                    Pricebook2Id = pb.Id,
                    Product2Id = testProduct.Id,
                    UnitPrice = 100,
                    IsActive = true,
                    UseStandardPrice = false
                )
            );
        }
        insert customPbes;
        
        cgcloud__Account_Template__c testCustomerTemplate = new cgcloud__Account_Template__c(
            Name='Retailer',
            cgcloud__Description_Language_1__c='Retailer',
            cgcloud__Sales_Org__c='0001', 
            cgcloud__Active__c=true
        );
        insert testCustomerTemplate;



        // Create an account with Customer_Category__c = 'R1'
        Account testAccount = new Account(
            Name = 'Test Account',
            Customer_Category__c = 'R1', // Must match getPricebookdetails logic
            cgcloud__Account_Template__c=testCustomerTemplate.id
            
        );
        insert testAccount;


        // Create a contact linked to the account
        Contact testContact = new Contact(
            LastName = 'Test Contact',
            Email = 'test.user@example.com', // Must match user email
            AccountId = testAccount.Id
        );
        insert testContact;
       
      // Create a test User (Admin)
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = new User(
            Alias = 'adminusr',
            Email = 'admin@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Admin',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'adminsdfghj@test.com'
        );
        insert adminUser;
        
        // Create a test User (Non-Admin)
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User standardUser = new User(
            Alias = 'stdusr',
            Email = 'standard@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'standard@test.com'
            
        );
        insert standardUser;
        
       
        
        // Create a test Order
        Order testOrder = new Order(
            Name = 'Test Order',
            AccountId = testAccount.Id,
            Status = 'Draft',
            Pricebook2Id = customPricebooks[0].Id,
            EffectiveDate = Date.today()
        );
        insert testOrder;
        
        // Create a test Order Item
        OrderItem testOrderItem = new OrderItem(
            OrderId = testOrder.Id,
            PricebookEntryId = customPbes[0].Id,
            Quantity = 2,
            UnitPrice = 100.0
        );
        insert testOrderItem;
    }

   
    
 @isTest
    static void testFetchOrdersAsAdmin() {
        User adminUser = [SELECT Id FROM User WHERE Email = 'admin@test.com' LIMIT 1];
        System.runAs(adminUser) {
            Test.startTest();
            List<OrderController.OrderWrapper> orders = OrderController.fetchOrders();
            Test.stopTest();
            
            System.assertNotEquals(0, orders.size(), 'Admin should fetch orders');
            System.assertEquals('Test Order', orders[0].orderName);
        }
    }
    
    
   
    
}