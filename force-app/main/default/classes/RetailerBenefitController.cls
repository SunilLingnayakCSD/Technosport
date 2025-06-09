public with sharing class RetailerBenefitController {

    @AuraEnabled(cacheable=true)
    public static String getCurrentUserProfile() {
        Id profileId = UserInfo.getProfileId();
        Profile p = [SELECT Name FROM Profile WHERE Id = :profileId LIMIT 1];
        return p.Name;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getAllTierNames() {
        List<String> names = new List<String>();
        for (Tier__c t : [SELECT Name FROM Tier__c]) {
            names.add(t.Name);
        }
        return names;
    }

    @AuraEnabled(cacheable=true)
    public static List<Benefit__c> getAllBenefitNames() {
        return [SELECT Name FROM Benefit__c];
    }
    

   /* @AuraEnabled(cacheable=true)
    public static List<String> getStatusPicklistValues() {
        List<String> vals = new List<String>();
        for (Schema.PicklistEntry pe : Retailer_Benefit__c.Status__c.getDescribe().getPicklistValues()) {
            vals.add(pe.getLabel());
        }
        System.debug('vals----->'+vals);
        return vals;
    }*/
    
    
    @AuraEnabled(cacheable=true)
public static Map<String, Object> getStatusPicklistValues() {
    Map<String, Object> response = new Map<String, Object>();

    // 1. Fetch picklist values
    List<Map<String, Object>> statusValues = new List<Map<String, Object>>();
    for (Schema.PicklistEntry pe : Retailer_Benefit__c.Status__c.getDescribe().getPicklistValues()) {
        Map<String, Object> statusEntry = new Map<String, Object>();
        statusEntry.put('label', pe.getLabel());
        statusEntry.put('value', pe.getValue());
        statusEntry.put('requiresLink', pe.getValue() == 'Yes'); // Example rule
        statusValues.add(statusEntry);
    }
    response.put('statusOptions', statusValues);

    // 2. Query Retailer_Benefit__c records with Link__c field
    List<Retailer_Benefit__c> benefits = [
        SELECT Id, Name, Status__c, Link__c
        FROM Retailer_Benefit__c
    ];
    System.debug(benefits);

    List<Map<String, String>> benefitData = new List<Map<String, String>>();
    for (Retailer_Benefit__c rb : benefits) {
        benefitData.add(new Map<String, String>{
            'id' => rb.Id,
            'status' => rb.Status__c,
            'link' => rb.Link__c
        });
    }

    response.put('benefits', benefitData);

    return response;
}


   @AuraEnabled
    public static List<RetailerBenefitWrapper> getFilteredRetailerBenefits(
        String tierName,
        String quarterType,
        String yearType) {

        /* ---------- 1. Build SOQL ------------------------------------ */
        String escTier    = tierName    == null ? '' : String.escapeSingleQuotes(tierName);
        String escQuarter = quarterType == null ? '' : String.escapeSingleQuotes(quarterType);
        String escYear    = yearType    == null ? '' : String.escapeSingleQuotes(yearType);

        List<String> whereParts = new List<String>();

        if (escTier != '')
            whereParts.add('Account__r.Retailer_Tier__r.Name = \'' + escTier + '\'');

        /* Benefit-type logic:
         *   • One Time            → always
         *   • Yearly              → year = selected
         *   • Qx (Q1…Q4) selected → quarter + year
         */
        List<String> typeClauses = new List<String>();

        // One-Time (no year filter)
        typeClauses.add('Type__c = \'One Time\'');

        // Yearly for the selected year
        if (escYear != '')
            typeClauses.add('(Type__c = \'Yearly\' AND Benefit_Year__c = \'' + escYear + '\')');

        // Quarterly for selected quarter + year
        if (escQuarter != '' && escYear != '')
            typeClauses.add('(Type__c = \'' + escQuarter +
                            '\' AND Benefit_Year__c = \'' + escYear + '\')');

        /* Combine WHERE clause */
        if (!typeClauses.isEmpty())
            whereParts.add('(' + String.join(typeClauses, ' OR ') + ')');

        String soql =
            'SELECT Id, Account__c, Account__r.Id, Account__r.Name, ' +
            '       Account__r.Retailer_Tier__r.Name, ' +
            '       Type__c, Status__c, Benefit__r.Name, Benefit__r.Link_Required__c, ' +
            '       Link__c, Benefit_Year__c ' +
            'FROM   Retailer_Benefit__c ' +
            (whereParts.isEmpty() ? '' : 'WHERE ' + String.join(whereParts, ' AND '));

        List<Retailer_Benefit__c> benefits = Database.query(soql);

        /* ---------- 2. Map Retailer-Year → Purchase ------------------ */
        Set<Id> acctIds = new Set<Id>();
        for (Retailer_Benefit__c b : benefits)
            if (b.Account__c != null) acctIds.add(b.Account__c);

        Map<String, Retailer_Purchase__c> purchaseMap = new Map<String, Retailer_Purchase__c>();

        if (!acctIds.isEmpty() && escYear != '') {
            for (Retailer_Purchase__c p : [
                SELECT Retailer__c, Year__c,
                       Q1_Purchase__c, Q2_Purchase__c, Q3_Purchase__c, Q4_Purchase__c
                FROM   Retailer_Purchase__c
                WHERE  Retailer__c IN :acctIds
                AND    Year__c     = :yearType
            ]) {
                purchaseMap.put(p.Retailer__c + '|' + p.Year__c, p);
            }
        }

        /* ---------- 3. Wrap results ---------------------------------- */
        List<RetailerBenefitWrapper> out = new List<RetailerBenefitWrapper>();

        for (Retailer_Benefit__c b : benefits) {
            RetailerBenefitWrapper w = new RetailerBenefitWrapper();
            w.benefit        = b;
            w.purchaseAmount = 0;

            if (escQuarter != '' && escYear != '') {
                Retailer_Purchase__c p =
                    purchaseMap.get(b.Account__c + '|' + escYear);

                if (p != null) {
                    if      (escQuarter == 'Q1') w.purchaseAmount = p.Q1_Purchase__c == null ? 0 : p.Q1_Purchase__c;
                    else if (escQuarter == 'Q2') w.purchaseAmount = p.Q2_Purchase__c == null ? 0 : p.Q2_Purchase__c;
                    else if (escQuarter == 'Q3') w.purchaseAmount = p.Q3_Purchase__c == null ? 0 : p.Q3_Purchase__c;
                    else if (escQuarter == 'Q4') w.purchaseAmount = p.Q4_Purchase__c == null ? 0 : p.Q4_Purchase__c;
                }
            }
            out.add(w);
        }
        return out;
    }

    @AuraEnabled
    public static void updateRetailerBenefitStatuses(List<Retailer_Benefit__c> updatedBenefits) {
        update updatedBenefits;
    }

    public class RetailerBenefitWrapper {
        @AuraEnabled public Retailer_Benefit__c benefit;
        @AuraEnabled public Decimal purchaseAmount;
    }
}