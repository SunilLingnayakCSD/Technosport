public class webToLead {
    @AuraEnabled
    public static Map<String, String> insertLead(Lead__c obj) {
        Map<String, String> response = new Map<String, String>();
        String duplicateField = '';   
        try {
            // Set the Lead Status if not already set
            if (obj.Lead_Status__c == null) {
                obj.Lead_Status__c = 'New';
                system.debug('obj.Lead_Status__c: ' + obj.Lead_Status__c);
            }

            if(obj.Email__c !=null && obj.Phone__c!=null){
            // Query for existing duplicates based on Phone and Email
            List<Lead__c> ld = [SELECT Id, Phone__c, Email__c FROM Lead__c WHERE Phone__c = :obj.Phone__c OR Email__c = :obj.Email__c LIMIT 1];
            if (!ld.isEmpty()) {
                Lead__c existingLead = ld[0];
                

                // Check which field is duplicate and set the response message accordingly
                if (existingLead.Phone__c != null && existingLead.Phone__c == obj.Phone__c) {
                    duplicateField = 'Phone';
                }
                if (existingLead.Email__c != null && existingLead.Email__c == obj.Email__c) {
                    duplicateField = 'Email';
                }

               // response.put('status', 'duplicate');
               //  response.put('duplicateField', duplicateField);
              //  response.put('message', 'Duplicate ' + duplicateField + ' found.');
              //  return response;
            }}

           
            insert obj; 

            response.put('status', 'success');
            response.put('message', 'Lead inserted successfully with ID: ' + obj.Id);
        } catch (DmlException e) {
           
            if (e.getMessage().contains('DUPLICATES_DETECTED')) {
                response.put('status', 'duplicate');
                response.put('message', 'Duplicate lead detected'+ e.getMessage());
            } else {
                response.put('status', 'error');
                response.put('message', 'Error inserting lead: ' + e.getMessage());
            }
        } catch (Exception e) {
            // Catch any other exceptions and return an error response
            response.put('status', 'error');
            response.put('message', 'Error inserting lead: ' + e.getMessage());
        }

        return response;
    }
}