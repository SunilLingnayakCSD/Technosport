public class leadGeneration {
     @AuraEnabled
    public static Id insertLead(Lead obj){
        system.debug('lead obj'+obj);
        insert obj;
        system.debug(obj.id);
        return obj.id;
        }
}