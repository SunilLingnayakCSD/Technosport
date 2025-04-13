@isTest
public class webToLeadTest {

    // Helper method to create a lead
    private static Lead__c createLead(String phone, String email, String leadStatus) {
        return new Lead__c(
            Phone__c = phone,
            Email__c = email,
            Lead_Status__c = leadStatus,
            Company__c = 'Kasmo',
            City__c = 'Davangere',
            Pincode__c = '577555',
            Category_of_store_you_are_dealing_with__c = 'Family Readymade shop'
        );
    }

    @isTest
    public static void testInsertLeadSuccess() {
        // Create a new Lead with valid data
        Lead__c testLead = createLead('1234567890', 'test@example.com', 'New');
        
        // Mock the result from the webToLead.insertLead method
        Test.startTest();
        Map<String, String> response = webToLead.insertLead(testLead);
        Test.stopTest();
        
        // Assertions
        System.assertEquals('success', response.get('status'));
        System.assert(response.get('message').contains('Lead inserted successfully'));

        // Verify that the lead was inserted into the database
        Lead__c insertedLead = [SELECT Id, Phone__c, Email__c FROM Lead__c WHERE Phone__c = '1234567890' LIMIT 1];
        System.assertNotEquals(null, insertedLead);
        System.assertEquals('1234567890', insertedLead.Phone__c);
        System.assertEquals('test@example.com', insertedLead.Email__c);
    }

    @isTest
    public static void testInsertLeadDuplicatePhone() {
        // Create and insert a lead with the same phone number
        Lead__c existingLead = createLead('1234567890', 'existing@example.com', 'New');
        insert existingLead;
        
        // Create a new lead with the same phone number to simulate a duplicate
        Lead__c duplicateLead = createLead('1234567890', 'duplicate@example.com', 'New');
        
        // Mock the result from the webToLead.insertLead method
        Test.startTest();
        Map<String, String> response = webToLead.insertLead(duplicateLead);
        Test.stopTest();
        
        // Assertions
        System.assertEquals('duplicate', response.get('status'));
       // System.assert(response.get('message').contains('Duplicate Phone found.'));
    }

    @isTest
    public static void testInsertLeadDuplicateEmail() {
        // Create and insert a lead with the same email
        Lead__c existingLead = createLead('9876543210', 'duplicate@example.com', 'New');
        insert existingLead;
        
        // Create a new lead with the same email to simulate a duplicate
        Lead__c duplicateLead = createLead('1234567890', 'duplicate@example.com', 'New');
        
        // Mock the result from the webToLead.insertLead method
        Test.startTest();
        Map<String, String> response = webToLead.insertLead(duplicateLead);
        Test.stopTest();
        
        // Assertions
        System.assertEquals('duplicate', response.get('status'));
       // System.assert(response.get('message').contains('Duplicate Email found.'));
    }

    @isTest
    public static void testInsertLeadMissingStatus() {
        // Create a new Lead__c object without Lead_Status__c
        Lead__c testLead = createLead('1234567890', 'test@example.com', null);
        
        // Mock the result from the webToLead.insertLead method
        Test.startTest();
        Map<String, String> response = webToLead.insertLead(testLead);
        Test.stopTest();
        
        // Assertions
        //System.assertEquals('error', response.get('status'));
       // System.assert(response.get('message').contains('Lead Status is required.'));
    }

    @isTest
    public static void testInsertLeadExceptionHandling() {
        // Simulate an error by passing a null Lead__c object
        Lead__c testLead = null;

        // Mock the result from the webToLead.insertLead method
        Test.startTest();
        Map<String, String> response = webToLead.insertLead(testLead);
        Test.stopTest();
        
        // Assertions
        System.assertEquals('error', response.get('status'));
        System.assert(response.get('message').contains('Error inserting lead'));
    }

    @isTest
    public static void testInsertLeadWithIncompleteData() {
        // Create a lead with missing required fields like Phone or Email
        Lead__c testLead = createLead(null, null, 'New');
        
        // Mock the result from the webToLead.insertLead method
        Test.startTest();
        Map<String, String> response = webToLead.insertLead(testLead);
        Test.stopTest();
        
        // Assertions
        System.assertEquals('error', response.get('status'));
        System.debug('response-->'+response.get('message'));
        System.assert(response.get('message').contains('REQUIRED_FIELD_MISSING'));
    }
}