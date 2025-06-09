@isTest
public class InsertOrderMainTest {
   /* @isTest
    public static void testCallSuitableMethod_NotAdmin() {
        // Set up test data for a non-admin user
        User testUser = new User(
            Username = 'testuser@777example.com',
            Email = 'testuser@example.com',
            Alias = 'tesr',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id, // Assumes Standard User profile is not Sales Representative
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName='testlast'
        );
        insert testUser;

        // Create test data for the InsertOrderMain method
        List<Map<String, Object>> productsList = new List<Map<String, Object>>();
        Map<String, Object> product = new Map<String, Object>();
        product.put('productName', 'Test Product');
        product.put('quantity', 10);
        productsList.add(product);

        // Test method for non-admin user
        Test.startTest();
        Boolean result = InsertOrderMain.callSuitableMethod(productsList, testUser.Id, null, null);
        Test.stopTest();

        // Verify the result
        System.assertEquals(true, result, 'The order should be created for non-admin user.');
    }  */

    @isTest
    public static void testCallSuitableMethod_Admin() {
        // Set up test data for an admin user (Sales Representative)
        User testUser = new User(
            Username = 'testadmin@999example.com',
            Email = 'testadmin@example.com',
            Alias = 'tedmin',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Representative' LIMIT 1].Id, // Sales Representative profile
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LastName='adminlast'
        );
        insert testUser;

        // Create test data for the InsertOrderMain method
        List<Map<String, Object>> productsList = new List<Map<String, Object>>();
        Map<String, Object> product = new Map<String, Object>();
        product.put('productName', 'Test Product');
        product.put('quantity', 10);
        productsList.add(product);

        // Test method for admin user (Sales Representative)
        Test.startTest();
        Boolean result = InsertOrderMain.callSuitableMethod(productsList, testUser.Id, 'someVisitId', 'someDistributorId');
        Test.stopTest();

        // Verify the result
        System.assertEquals(false, result, 'The order should be created for admin user.');
    }  
}