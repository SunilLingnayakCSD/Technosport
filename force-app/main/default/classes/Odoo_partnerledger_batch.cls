global without sharing class Odoo_partnerledger_batch implements Database.Batchable<sobject>,Database.AllowsCallouts,Database.Stateful, Schedulable {
    public static String baseUrl ;
    public static Decimal USERId;
    public static String ODOO_DB;
    public static String objectModule='account.move.line';
    public static String searchMethod='search_read';
    public static String ODOO_PASSWORD;
    static {
        OdooSettings__mdt odooSettings = [SELECT MasterLabel, ODOO_INV_URL__c,ODOO_PWD_KEY__c, ODOO_USER_ID__c, ODOO_DB__c, ODOO_PASSWORD__c
                                          FROM OdooSettings__mdt 
                                          WHERE MasterLabel = 'OdooCrdentials' LIMIT 1];
        System.debug('custom Metadata------->'+odooSettings);
        if (odooSettings != null) {
            baseUrl = odooSettings.ODOO_INV_URL__c;
            USERId = odooSettings.ODOO_USER_ID__c;
            ODOO_DB = odooSettings.ODOO_DB__c;
            ODOO_PASSWORD = odooSettings.ODOO_PASSWORD__c;
        } else {
            throw new AuraHandledException('No Odoo Credentials found in OdooSettings__mdt.');
        }
        
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([select id,External_Id__c  from Account where External_Id__c!=null]);
    }
    
    global void execute(Database.BatchableContext bc, List<Account> records){
        List<Integer> ledgerIds = new List<Integer>();
        for(Account acc:records){
            if (acc.External_Id__c != null) {
                try {
                    ledgerIds.add(Integer.valueOf(acc.External_Id__c));
                } catch (Exception e) {
                    System.debug('Invalid External_Id__c on Account: ' + acc.Id);
                }
            }
        }
        if (ledgerIds.isEmpty()) {
            System.debug('No valid ledgerIds found. Skipping callout.');
            return;
        }
        System.debug('The Ledger Ids are : '+ledgerIds);
        List<Account> accList=new List<Account>();
        //String formattedStartDate = Date.today().format('yyyy-MM-dd');
       Date todayval = Date.today();

String formattedStartDate=String.valueOf(todayval)	;		


String formattedEndDate = Datetime.now().addHours(24).format('yyyy-MM-dd HH:mm:ss');
System.debug('formattedStartDate'+formattedStartDate);
        System.debug('formattedEndDate'+formattedEndDate);
        
        Map<String,Object> requestBody=new Map<String,Object>();
        requestBody.put('jsonrpc','2.0');
        requestBody.put('method','call');
        Map<String,Object> params=new Map<String,Object>();
        params.put('service','object');
        params.put('method','execute_kw');
        List<Object> domainFilters = new List<Object>{
            new List<Object>{'account_id', 'in', new List<Integer>{49, 63}},
            new List<Object>{'partner_id','in',ledgerIds},
            new List<Object>{'parent_state','=','posted'},
            new List<Object>{'write_date','>=',formattedStartDate},
            new List<Object>{'write_date','<=',formattedEndDate}
        };
        List<Object> args=new List<Object>{
            ODOO_DB,
            USERId,
            ODOO_PASSWORD,
            objectModule,
            searchMethod,
            new List<Object>{
                domainFilters
            },
            new Map<String,Object>{
                'fields'=>new List<String>{
                    'id','move_id','name','partner_id','account_id','invoice_date','date_maturity','amount_currency','matching_number','debit',
                    'credit','balance'
                }
            }
        };
        params.put('args',args);
        requestBody.put('params',params);
        String jsonBody=JSON.serialize(requestBody);
        System.debug('The request json is : '+jsonBody);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(baseUrl);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        if(res.getStatusCode()==200){
            System.debug('The Response is :'+res);
            System.debug(JSON.serializePretty(res.getBody()));
            String resString = res.getBody();
            System.debug('The Response in String Format is : '+resString);
            List<Partner_Ledger__c> listofPartnerLedger=parseLedgerDetails(resString);
            System.debug('The List of Partner Ledger is : '+listofPartnerLedger);
            if(listofPartnerLedger!=null && !listofPartnerLedger.isEmpty()){
                upsert listofPartnerLedger ExternalId__c;
            }
            
        } else {
            System.debug('Error: ' + res.getStatusCode() + ' - ' + res.getBody());
        }
        
    }
  private static List<Partner_Ledger__c> parseLedgerDetails(String resString) {
    Map<String, Object> resultData = (Map<String, Object>) JSON.deserializeUntyped(resString);
    List<Object> resList = (List<Object>) resultData.get('result');
    List<Partner_Ledger__c> partnerLedgerList = new List<Partner_Ledger__c>();

    if (resList.isEmpty()) {
        return null;
    }
    Set<String> moveIds = new Set<String>();
    Set<String> partnerExternalIds = new Set<String>();

    for (Object obj : resList) {
        Map<String, Object> listofPartnerLedger = (Map<String, Object>) obj;

        List<Object> moveIdDetails = (List<Object>) listofPartnerLedger.get('move_id');
        if (moveIdDetails != null && !moveIdDetails.isEmpty() && moveIdDetails[0] != null) {
            moveIds.add(String.valueOf(moveIdDetails[0]));
        }
        List<Object> partnerDetails = (List<Object>) listofPartnerLedger.get('partner_id');
        if (partnerDetails != null && !partnerDetails.isEmpty() && partnerDetails[0] != null) {
            partnerExternalIds.add(String.valueOf(partnerDetails[0]));
        }
    }

    Map<String, Id> moveIdToInvoiceId = new Map<String, Id>();
    if (!moveIds.isEmpty()) {
        for (Invoice__c inv : [
            SELECT Id, Invoice_Id__c FROM Invoice__c WHERE Invoice_Id__c IN :moveIds
        ]) {
            moveIdToInvoiceId.put(inv.Invoice_Id__c, inv.Id);
        }
    }

    Map<String, Id> partnerIdToAccountId = new Map<String, Id>();
    if (!partnerExternalIds.isEmpty()) {
        for (Account acc : [
            SELECT Id, External_Id__c FROM Account WHERE External_Id__c IN :partnerExternalIds
        ]) {
            partnerIdToAccountId.put(acc.External_Id__c, acc.Id);
        }
    }

    for (Object obj : resList) {
        Map<String, Object> listofPartnerLedger = (Map<String, Object>) obj;
        Partner_Ledger__c partnerLedger = new Partner_Ledger__c();

        List<Object> moveIdDetails = (List<Object>) listofPartnerLedger.get('move_id');
        String moveIdString = (moveIdDetails != null && !moveIdDetails.isEmpty()) ? String.valueOf(moveIdDetails[0]) : null;
        partnerLedger.Invoice__c = moveIdString != null && moveIdToInvoiceId.containsKey(moveIdString)
            ? moveIdToInvoiceId.get(moveIdString)
            : null;

        List<Object> partnerDetails = (List<Object>) listofPartnerLedger.get('partner_id');
        String partnerIdString = (partnerDetails != null && !partnerDetails.isEmpty()) ? String.valueOf(partnerDetails[0]) : null;
        partnerLedger.Account__c = partnerIdString != null && partnerIdToAccountId.containsKey(partnerIdString)
            ? partnerIdToAccountId.get(partnerIdString)
            : null;

        List<Object> accountid = (List<Object>) listofPartnerLedger.get('account_id');
        partnerLedger.account_id__c = accountid != null && !accountid.isEmpty() ? Integer.valueOf(accountid[0]) : null;
        partnerLedger.account_name__c = accountid != null && !accountid.isEmpty() ? String.valueOf(accountid[0]) : null;
        partnerLedger.Ledger_Name__c = listofPartnerLedger.get('name') != false ? (String) listofPartnerLedger.get('name') : 'unknown';
        partnerLedger.Invoice_Date__c = listofPartnerLedger.get('invoice_date') != false ? Date.valueOf((String) listofPartnerLedger.get('invoice_date')) : null;
        partnerLedger.Date_Maturity__c = listofPartnerLedger.get('date_maturity') != false ? Date.valueOf((String) listofPartnerLedger.get('date_maturity')) : null;
        partnerLedger.Amount_Currency__c = listofPartnerLedger.get('amount_currency') != false ? (Decimal) listofPartnerLedger.get('amount_currency') : 0;
        partnerLedger.Matching_Number__c = listofPartnerLedger.get('matching_number') != false ? (String) listofPartnerLedger.get('matching_number') : '';
        partnerLedger.Debit__c = listofPartnerLedger.get('debit') != false ? (Decimal) listofPartnerLedger.get('debit') : 0;
        partnerLedger.Credit__c = listofPartnerLedger.get('credit') != false ? (Decimal) listofPartnerLedger.get('credit') : 0;
        partnerLedger.Balance__c = listofPartnerLedger.get('balance') != false ? (Decimal) listofPartnerLedger.get('balance') : 0;
        partnerLedger.ExternalId__c = String.valueOf(listofPartnerLedger.get('id'));

        partnerLedgerList.add(partnerLedger);
    }

    return partnerLedgerList;
}

    global void finish(Database.BatchableContext bc){
        System.debug('The Ledger List is : ');
    }
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new Odoo_partnerledger_batch());
    }
    
    
    
    
}