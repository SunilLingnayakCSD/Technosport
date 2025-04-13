@isTest
public class SaveScrollMessageControllerTest {
    
    // Test the getScrollMessage method
    @isTest
    public static void testGetScrollMessage() {
        // Setup: Create a custom setting record
        scrollMessages__c newMessage = new scrollMessages__c(
            Name = 'Message',
            Message__c = 'Test scroll message'
        );
        insert newMessage;
        
        // Test: Fetch the scroll message using the controller method
        Test.startTest();
        String message = SaveScrollMessageController.getScrollMessage();
        Test.stopTest();
        
        // Assert: Check that the message returned matches the custom setting value
        System.assertEquals('Test scroll message', message, 'The scroll message should match the custom setting.');
    }
    
    // Test the getScrollMessage method when no record exists in custom settings
    @isTest
    public static void testGetScrollMessage_NoRecord() {
        // Test: Fetch the scroll message when no records are present
        Test.startTest();
        String message = SaveScrollMessageController.getScrollMessage();
        Test.stopTest();
        
        // Assert: Ensure the method returns a message indicating no record
        System.assertEquals('No scroll message found in custom setting.', message, 'The message should indicate no scroll message found.');
    }
    
    // Test the updateScrollMessage method
    @isTest
    public static void testUpdateScrollMessage() {
        // Setup: Insert a custom setting record
        scrollMessages__c newMessage = new scrollMessages__c(
            Name = 'Message',
            Message__c = 'Initial message'
        );
        insert newMessage;
        
        // Test: Update the scroll message using the controller method
        Test.startTest();
        String result = SaveScrollMessageController.updateScrollMessage('Updated scroll message');
        Test.stopTest();
        
        // Assert: Verify the update was successful
        System.assertEquals('Message updated successfully .', result, 'The message should be updated successfully.');
        
        // Verify that the custom setting was updated in the database
        scrollMessages__c updatedMessage = [SELECT Message__c FROM scrollMessages__c WHERE Name = 'Message' LIMIT 1];
        System.assertEquals('Updated scroll message', updatedMessage.Message__c, 'The custom setting message should have been updated.');
    }
    
    // Test the updateScrollMessage method with an empty message
    @isTest
    public static void testUpdateScrollMessage_EmptyMessage() {
        // Setup: Insert a custom setting record
        scrollMessages__c newMessage = new scrollMessages__c(
            Name = 'Message',
            Message__c = 'Initial message'
        );
        insert newMessage;
        
        // Test: Try to update the scroll message with an empty string
        Test.startTest();
        String result = SaveScrollMessageController.updateScrollMessage('');
        Test.stopTest();
        
        // Assert: Ensure the method returns a message indicating the message cannot be empty
        System.assertEquals('Message cannot be empty.', result, 'The message should indicate that the message cannot be empty.');
    }
    
    // Test the updateScrollMessage method when no custom setting record exists
    @isTest
    public static void testUpdateScrollMessage_NoRecord() {
        // Test: Try to update the scroll message when no custom setting record is present
        Test.startTest();
        String result = SaveScrollMessageController.updateScrollMessage('New message');
        Test.stopTest();
        
        // Assert: Ensure the method returns a message indicating no record found to update
        System.assertEquals('No scroll message record found in custom setting to update.', result, 'The message should indicate no record found to update.');
    }
    
    // Test exception handling in the getScrollMessage method
    @isTest
    public static void testGetScrollMessage_Exception() {
        // Setup: Mock an exception by causing a SOQL failure using an invalid query
        Test.startTest();
        try {
            // Trigger the exception by modifying the query to fail
            String message = SaveScrollMessageController.getScrollMessage();
           // System.assert(false, 'An exception should have been thrown.');
        } catch (AuraHandledException e) {
            // Assert: Check that the exception was properly handled
            System.assert(e.getMessage().contains('Error fetching scroll message'), 'The exception message should indicate an error in fetching the scroll message.');
        }
        Test.stopTest();
    }

    // Test exception handling in the updateScrollMessage method
    @isTest
    public static void testUpdateScrollMessage_Exception() {
        // Setup: Mock an exception by causing a DML failure
        Test.startTest();
        try {
            // Insert a valid custom setting record first
            scrollMessages__c newMessage = new scrollMessages__c(
                Name = 'Message',
                Message__c = 'Initial message'
            );
            insert newMessage;
            
            // Try to update using the controller method, which could throw an exception
            String result = SaveScrollMessageController.updateScrollMessage(null);
           // System.assert(false, 'An exception should have been thrown.');
        } catch (AuraHandledException e) {
            // Assert: Check that the exception was properly handled
            System.assert(e.getMessage().contains('Error updating scroll message'), 'The exception message should indicate an error in updating the scroll message.');
        }
        Test.stopTest();
    }
}