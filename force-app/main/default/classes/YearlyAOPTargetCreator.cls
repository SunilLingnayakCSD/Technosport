global class YearlyAOPTargetCreator implements Database.Batchable<Account>, Schedulable {

    global void execute(SchedulableContext sc) {
        Database.executeBatch(this, 200);
    }

    global Iterable<Account> start(Database.BatchableContext bc) {
        Id customerRTId = getAccountRecordTypeId('Customer');
        List<Account> accounts = [SELECT Id FROM Account WHERE RecordTypeId = :customerRTId];
        return accounts;
    }

    global void execute(Database.BatchableContext bc, List<Account> scope) {
        Integer currentYear = Date.today().year();
        String yearString = String.valueOf(currentYear);

        Set<Id> accountIds = new Set<Id>();
        for (Account acc : scope) {
            accountIds.add(acc.Id);
        }

        Set<Id> accountsWithRetailerTarget = new Set<Id>();
        for (Retailer_AOP_Target__c rt : [
            SELECT Account__c FROM Retailer_AOP_Target__c WHERE Account__c IN :accountIds AND Year__c = :yearString
        ]) {
            accountsWithRetailerTarget.add(rt.Account__c);
        }

        List<Retailer_AOP_Target__c> retailerTargetsToInsert = new List<Retailer_AOP_Target__c>();
        for (Account acc : scope) {
            if (!accountsWithRetailerTarget.contains(acc.Id)) {
                retailerTargetsToInsert.add(new Retailer_AOP_Target__c(Account__c = acc.Id));
            }
        }

        List<User> salesReps = [SELECT Id FROM User WHERE IsActive = true AND Profile.Name = 'Sales Representative'];

        Set<Id> salesRepIds = new Set<Id>();
        for (User rep : salesReps) {
            salesRepIds.add(rep.Id);
        }

        Set<Id> salesRepsWithAsmTarget = new Set<Id>();
        for (ASM_AOP_Target__c asm : [
            SELECT Sales_Rep__c FROM ASM_AOP_Target__c WHERE Sales_Rep__c IN :salesRepIds AND Year__c = :yearString
        ]) {
            salesRepsWithAsmTarget.add(asm.Sales_Rep__c);
        }

        List<ASM_AOP_Target__c> asmTargetsToInsert = new List<ASM_AOP_Target__c>();
        for (User rep : salesReps) {
            if (!salesRepsWithAsmTarget.contains(rep.Id)) {
                asmTargetsToInsert.add(new ASM_AOP_Target__c(Sales_Rep__c = rep.Id));
            }
        }

        if (!retailerTargetsToInsert.isEmpty()) {
            insert retailerTargetsToInsert;
        }
        if (!asmTargetsToInsert.isEmpty()) {
            insert asmTargetsToInsert;
        }
    }

    global void finish(Database.BatchableContext bc) {
        // optional
    }

    private Id getAccountRecordTypeId(String rtName) {
        return [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = :rtName LIMIT 1].Id;
    }
}