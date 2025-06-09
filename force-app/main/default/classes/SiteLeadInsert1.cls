public class SiteLeadInsert1 {
    @AuraEnabled
    public static String insertLead(Lead obj) {
        System.debug('Received lead object: ' + obj);
        System.debug('lead Phone-->: ' + obj.Phone);
        System.debug('lead Email--->: ' + obj.Email);
        
        
        // Query for existing leads with the same phone number or email
        List<Lead> ld = [SELECT Id, FirstName, LastName, Phone, Email FROM Lead WHERE Phone = :obj.Phone OR Email = :obj.Email ];
        System.debug('Found leads with matching phone or email: ' + ld);
        
        String duplicateMessage = '';
        
        // If no matching leads are found, insert the new lead
        if (ld.isEmpty()) {
            insert obj;
            return obj.Id; // Return the ID of the new lead
        }
        else if (ld[0].Phone == obj.Phone) {
            duplicateMessage += 'Duplicate phone number.';
        }
        else if (ld.size() > 0 && ld[0].Email == obj.Email) {
            duplicateMessage += 'Duplicate email address.';
        }
        
        // If lead exists based on phone or email, return a duplicate message
        /*   if (!ld.isEmpty()) {
// Check if the duplicate is based on Phone or Email
if (ld.size() > 0 && ld[0].Phone == obj.Phone) {
duplicateMessage += 'Duplicate phone number. ';
}
if (ld.size() > 0 && ld[0].Email == obj.Email) {
duplicateMessage += 'Duplicate email address.';
}
}
*/
        return duplicateMessage; // Return the duplicate message
    }
    
    @AuraEnabled(cacheable = true)
    public static String getRefIdFromLead(String leadId) {
        List<Lead> led = [SELECT Id, Name, Lead_Reference_Number__c, Email FROM Lead WHERE Id = :leadId LIMIT 1];
        System.debug('Lead Reference ID: ' + led[0].Lead_Reference_Number__c);
        return led[0].Lead_Reference_Number__c;
    }
}