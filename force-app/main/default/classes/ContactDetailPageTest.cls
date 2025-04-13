@isTest
public class ContactDetailPageTest {

    // Test method for a valid contactId
    @isTest
    public static void testGetContact_ValidContactId() {
        // Create a test account and contact
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            AccountId = acc.Id,
            Email = 'john.doe@example.com',
            Phone = '123-456-7890',
            Birthdate = Date.today(),
            MailingStreet = '123 Test St',
            MailingCity = 'Test City',
            MailingState = 'TS',
            MailingPostalCode = '12345',
            MailingCountry = 'Testland',
            Picture__c = 'https://example.com/pic.jpg'
        );
        insert testContact;

        // Call the method with a valid contactId
        Test.startTest();
        Contact resultContact = ContactDetailPage.getContact(testContact.Id);
        Test.stopTest();

        // Assert that the contact returned matches the inserted contact
        System.assertNotEquals(resultContact, null);
        System.assertEquals(resultContact.Id, testContact.Id);
        System.assertEquals(resultContact.FirstName, 'John');
        System.assertEquals(resultContact.LastName, 'Doe');
        System.assertEquals(resultContact.Email, 'john.doe@example.com');
    }

    // Test method for an invalid contactId (non-existent contact)
    @isTest
    public static void testGetContact_InvalidContactId() {
        // Generate a random Id (non-existent contactId)
        Id invalidContactId = '003000000000000AAA';

        Test.startTest();
        try {
            // Call the method with an invalid contactId
            ContactDetailPage.getContact(invalidContactId);
            System.assert(false, 'Expected an exception to be thrown.');
        } catch (AuraHandledException e) {
            // Verify that the exception message is correct
            //System.assertEquals(e.getMessage(), 'Contact not found for the given ID: ' + invalidContactId);
        }
        Test.stopTest();
    }

    // Test method for a null contactId
    @isTest
    public static void testGetContact_NullContactId() {
        Test.startTest();
        try {
            // Call the method with a null contactId
            ContactDetailPage.getContact(null);
            System.assert(false, 'Expected an exception to be thrown.');
        } catch (AuraHandledException e) {
            // Verify that the exception message is correct
            //System.assertEquals(e.getMessage(), 'Contact ID cannot be null.');
        }
        Test.stopTest();
    }
}