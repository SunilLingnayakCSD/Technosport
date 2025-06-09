/*@RestResource(urlMapping='/odoo/webhook2')
global with sharing class WebhookToGetCustomer {
    
    @HttpPost
    global static void handleWebhookForCustomer() {
        try {
            // Parse incoming request body
            RestRequest req = RestContext.request;
            String requestBody = req.requestBody.toString();
            
            System.debug('Odoo Webhook Request Body: ' + requestBody);

            // Deserialize JSON payload into a map
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            System.debug('Payload: ' + JSON.serializePretty(payload));
            
            if (payload != null) {
                Contact con = new Contact();
                
                //Map name field
                if (payload.containsKey('name')) {
                    con.LastName = (String) payload.get('name');
                }
                if (payload.containsKey('id')) {
                    con.External_Contact_Id__c = String.valueOf(payload.get('id'));
                }

                // Map phone field
                if (payload.containsKey('phone')) {
                    con.Phone = String.valueOf(payload.get('phone')); // Map phone number
                }

                // Map email field
                if (payload.containsKey('email')) {
                    con.Email = String.valueOf(payload.get('email')); // Map email address
                }

                // Map contact_address field
                if (payload.containsKey('contact_address') && String.isNotBlank((String) payload.get('contact_address'))) {
                    con.MailingStreet = String.valueOf((String) payload.get('contact_address')); // Map address
                }

                System.debug('Mapped Contact: ' + JSON.serializePretty(con));

                // Insert the Contact record into Salesforce
                insert con;

                // Success response
                RestContext.response.statusCode = 200;
                RestContext.response.responseBody = Blob.valueOf('Webhook processed and Contact record created successfully');
            }
        } catch (Exception e) {
            System.debug('Error processing webhook: ' + e.getMessage());
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf('Error processing webhook: ' + e.getMessage());
        }
    }
}  */



@RestResource(urlMapping='/odoo/webhook2')
global with sharing class WebhookToGetCustomer {
    
    @HttpPost
    global static void handleWebhookForCustomer() {
        try {
            // Parse incoming request body
            RestRequest req = RestContext.request;
            String requestBody = req.requestBody.toString();
            
            System.debug('Odoo Webhook Request Body: ' + requestBody);

            // Deserialize JSON payload into a map
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            System.debug('Payload: ' + JSON.serializePretty(payload));
            
            if (payload != null) {
                Contact con = new Contact();
                
                // Map external ID field
                if (payload.containsKey('id')) {
                    con.External_Contact_Id__c = String.valueOf(payload.get('id'));
                }

                // Map name field
                if (payload.containsKey('name')) {
                    con.LastName = (String) payload.get('name');
                }

                // Map phone field
                if (payload.containsKey('phone')) {
                    con.Phone = String.valueOf(payload.get('phone'));
                }

                // Map email field
                if (payload.containsKey('email')) {
                    con.Email = String.valueOf(payload.get('email'));
                }

                // Map contact_address field
                if (payload.containsKey('contact_address') && String.isNotBlank((String) payload.get('contact_address'))) {
                    con.MailingStreet = String.valueOf((String) payload.get('contact_address'));
                }

                System.debug('Mapped Contact: ' + JSON.serializePretty(con));

                // Use upsert to either create or update the contact record
               // upsert con External_Contact_Id__c;

                // Success response
                RestContext.response.statusCode = 200;
                RestContext.response.responseBody = Blob.valueOf('Webhook processed. Contact record created/updated successfully.');
            }
        } catch (Exception e) {
            System.debug('Error processing webhook: ' + e.getMessage());
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf('Error processing webhook: ' + e.getMessage());
        }
    }
} 

/*@HttpPost
global static void processWebhook() {
    try {
        // Parse incoming request body
        RestRequest req = RestContext.request;
        String requestBody = req.requestBody.toString();
        
        System.debug('Odoo Webhook Request Body: ' + requestBody);

        // Deserialize JSON payload into a map
        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
        System.debug('Payload: ' + JSON.serializePretty(payload));
        
        if (payload != null) {
            String externalId = payload.containsKey('id') ? String.valueOf(payload.get('id')) : null;
            
            Contact conList;
            
            if (externalId != null) {
                // Check if a Contact with the given External ID already exists
                List<Contact> existingContacts = [SELECT Id FROM Contact WHERE External_Contact_Id__c = :externalId LIMIT 1];
                if (existingContacts.isEmpty()) {
                    Contact con = new Contact();
                    con.LastName = String.valueOf(payload.get('name'));
                    con.Phone = String.valueOf(payload.get('phone'));
                    con.External_Contact_Id__c = externalId;
                
                    try {
                        insert con;
                        System.debug('Contact created: ' + con.Id);
                    } catch (Exception e) {
                        System.debug('Error while inserting contact: ' + e.getMessage());
                    }
                }

            // Map fields from the payload
            if (payload.containsKey('name')) {
                conList.LastName = (String) payload.get('name');
            }
            if (payload.containsKey('phone')) {
                conList.Phone = String.valueOf(payload.get('phone'));
            }
            if (payload.containsKey('email')) {
                conList.Email = String.valueOf(payload.get('email'));
            }
            if (payload.containsKey('contact_address') && String.isNotBlank((String) payload.get('contact_address'))) {
                conList.MailingStreet = String.valueOf(payload.get('contact_address'));
            }

            System.debug('Mapped Contact: ' + JSON.serializePretty(conList));

            // Perform an upsert operation
            upsert conList External_Contact_Id__c;

            // Success response
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf('Webhook processed and Contact record created/updated successfully');
        }
        } }catch (Exception e) {
        System.debug('Error processing webhook: ' + e.getMessage());
        RestContext.response.statusCode = 500;
        RestContext.response.responseBody = Blob.valueOf('Error processing webhook: ' + e.getMessage());
    }
}
} */