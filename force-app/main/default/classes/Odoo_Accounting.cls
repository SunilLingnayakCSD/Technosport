@RestResource(urlMapping='/odoo/accounting/*')
global class Odoo_Accounting {
    global class AccountWrapper {
        public Decimal credit;
        public Decimal debit;
        public Integer id;
        public boolean is_b2b_customer;
        public Decimal residual_amount;
    }

    @HttpPost()
    global static void getAccountingDetails() {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        
        try {
            String requestBody = request.requestBody.toString();
            System.debug('**************requestBody' + requestBody);
            
            AccountWrapper wrapper = (AccountWrapper)JSON.deserialize(requestBody, AccountWrapper.class);
            
            if (wrapper == null) {
                throw new CustomException('Request body is missing or malformed.');
            }
            
            Id Recordtype;
            if (wrapper.is_b2b_customer == true) {
                Recordtype = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Distributor').getRecordTypeId();
            } else {
                Recordtype = null;
                System.debug('RecordType is null');
            }

            
            if (wrapper.id == null) {
                throw new CustomException('Missing or invalid Account ID.');
            }

            
            List<Account> acc = [SELECT Id, Name, External_Id__c, RecordTypeId 
                                 FROM Account 
                                 WHERE External_Id__c = :String.valueOf(wrapper.id) 
                                 AND RecordTypeId = :Recordtype];
            
           
            if (acc.isEmpty()) {
                throw new CustomException('No Account found for the provided External ID: ' + wrapper.id);
            }

            Account account = acc[0];
            account.Credit__c = (wrapper.credit != null) ? wrapper.credit : 0;
            account.Debit__c = (wrapper.debit != null) ? wrapper.debit : 0;
            account.residual_amount__c = (wrapper.residual_amount != null) ? wrapper.residual_amount : 0;
            
            update account;

            response.statusCode = 200;
            response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
                'status' => 'Success',
                'message' => 'Account Updated Successfully - ' + account.Id,
                'Account Id' => account.Id
            }));

            System.debug('Account updated successfully: ' + account.Id);
            
        } catch (CustomException ce) {
            
            response.statusCode = 400;  
            response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
                'status' => 'Error',
                'message' => 'Custom Error: ' + ce.getMessage()
            }));
            System.debug('Custom Exception: ' + ce.getMessage());
            
        } catch (DmlException dmlEx) {
            
            response.statusCode = 500; 
            response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
                'status' => 'Error',
                'message' => 'DML Error: ' + dmlEx.getMessage()
            }));
            System.debug('DML Exception: ' + dmlEx.getMessage());

        } catch (Exception e) {
            
            response.statusCode = 500;  
            response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
                'status' => 'Error',
                'message' => 'Error: ' + e.getMessage()
            }));
            System.debug('Encountered Error: ' + e.getMessage());
        }
    }

    public class CustomException extends Exception {}
}