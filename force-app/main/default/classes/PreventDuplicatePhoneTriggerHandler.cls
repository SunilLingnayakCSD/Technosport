public class PreventDuplicatePhoneTriggerHandler{

    public static void checkForDuplicatePhone(List<Account> newRecords, Map<Id, Account> oldRecords) {
        
        try {
            // Create a Set to hold the phone numbers from the new records
            Set<String> phoneNumbers = new Set<String>();
            for (Account cust : newRecords) {
                if (cust.Phone != null) {
                    phoneNumbers.add(cust.Phone);
                }
            }
            
            System.debug('Phone numbers from new records: ' + phoneNumbers);

          
            Set<Id> recordIds = new Set<Id>();
            for (Account cust : newRecords) {
                recordIds.add(cust.Id);
            }

            System.debug('Record IDs being processed: ' + recordIds);

            
            List<Account> existingCustomers = [SELECT Id, Phone 
                                               FROM Account 
                                               WHERE Phone IN :phoneNumbers 
                                               AND Id NOT IN :recordIds];

            System.debug('Existing Customers with matching phone numbers: ' + existingCustomers);

          
            Set<String> existingPhoneNumbers = new Set<String>();
            for (Account existingCustomer : existingCustomers) {
                existingPhoneNumbers.add(existingCustomer.Phone);
            }

           
            System.debug('Existing phone numbers found in the system: ' + existingPhoneNumbers);

           
            for (Account cust : newRecords) {
                if (cust.Phone != null && existingPhoneNumbers.contains(cust.Phone)) {
                   
                    System.debug('Duplicate phone number found for account: ' + cust.Phone);
                    
                    cust.addError('A record with this phone number already exists.');
                }
            }
        } catch (Exception e) {
            
            System.debug('Error in checkForDuplicatePhone method: ' + e.getMessage());
          
         }
    }
}