public class ContactDetailPage {
    @AuraEnabled(cacheable=true)
    public static Contact getContact(Id contactId) {
        // Check if contactId is null or invalid
        if (contactId == null) {
            throw new AuraHandledException('Contact ID cannot be null.');
        }
        
        // Query the contact
        List<Contact> contacts = [
            SELECT Id, LastName, FirstName, Salutation, Name, Title, Account.Name, Phone, Email,Birthdate,MobilePhone,
            MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry,Picture__c
            FROM Contact
            WHERE Id = :contactId
            LIMIT 1
        ];
        
        // Check if the contact is found
        if (contacts.isEmpty()) {
            throw new AuraHandledException('Contact not found for the given ID: ' + contactId);
        }
        
        // Return the contact if found
        return contacts[0];
    }
}