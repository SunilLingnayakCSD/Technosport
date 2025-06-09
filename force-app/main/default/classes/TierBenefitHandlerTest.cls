@isTest
public class TierBenefitHandlerTest {

    @testSetup
    static void setupTestData() {
        // Create Benefits
        List<Benefit__c> benefits = new List<Benefit__c>{
            new Benefit__c(Name='Yearly Benefit', Type__c='Yearly'),
            new Benefit__c(Name='Quarterly Benefit', Type__c='Quarterly'),
            new Benefit__c(Name='One Time Benefit', Type__c='One Time')
        };
        insert benefits;

        // Create Tier
        Tier__c tier = new Tier__c(Name='Gold');
        insert tier;

        // Link Tier to Benefits
        List<Tier_Benefit__c> tierBenefits = new List<Tier_Benefit__c>();
        for (Benefit__c b : benefits) {
            tierBenefits.add(new Tier_Benefit__c(Tier__c=tier.Id, Benefit__c=b.Id));
        }
        insert tierBenefits;

        // Create Account
        Account acc = new Account(
            Name = 'Test Retailer',
            Retailer_Tier__c = tier.Id,
            Current_Benefit_Year__c = '2025',
            Current_Benefit_Quater__c = 'Q2',
            BillingPostalCode='577428',
            Phone='9999000000'
        );
        insert acc;

        // Only pre-insert Yearly benefit
        insert new Retailer_Benefit__c(
            Account__c = acc.Id,
            Benefit__c = benefits[0].Id, // Yearly
            Type__c = 'Yearly',
            Benefit_Year__c = '2025',
            Status__c = 'Yes'
        );
    }

    @isTest
    static void testProcessTierChange_fullCoverage() {
        Account oldAcc = [SELECT Id, Retailer_Tier__c, Current_Benefit_Year__c, Current_Benefit_Quater__c FROM Account LIMIT 1];

        Account newAcc = new Account(
            Id = oldAcc.Id,
            Retailer_Tier__c = oldAcc.Retailer_Tier__c,
            Current_Benefit_Year__c = '2026',
            Current_Benefit_Quater__c = 'Q3'
        );

        Map<Id, Account> oldMap = new Map<Id, Account>{ oldAcc.Id => oldAcc };
        Map<Id, Account> newMap = new Map<Id, Account>{ newAcc.Id => newAcc };

        Test.startTest();
        TierBenefitHandler.processTierChange(oldMap, newMap);
        Test.stopTest();

        List<Retailer_Benefit__c> benefits = [
            SELECT Account__c, Benefit__c, Type__c, Benefit_Year__c
            FROM Retailer_Benefit__c
            WHERE Account__c = :oldAcc.Id AND Status__c = 'No'
        ];

        System.assert(!benefits.isEmpty(), 'Expected new benefits to be created');
    }

    @isTest
    static void testNoChange_noInsert() {
        Account acc = [SELECT Id, Retailer_Tier__c, Current_Benefit_Year__c, Current_Benefit_Quater__c FROM Account LIMIT 1];

        Map<Id, Account> oldMap = new Map<Id, Account>{ acc.Id => acc };
        Map<Id, Account> newMap = new Map<Id, Account>{ acc.Id => acc };

        Test.startTest();
        TierBenefitHandler.processTierChange(oldMap, newMap);
        Test.stopTest();

        System.assertEquals(0, [
            SELECT COUNT() FROM Retailer_Benefit__c
            WHERE Account__c = :acc.Id AND Status__c = 'No'
        ], 'No new benefits should have been created');
    }

    // ✅ [NEW TEST METHOD]
    @isTest
    static void testNullQuarter_usesCurrentDate() {
        Account acc = [SELECT Id, Retailer_Tier__c, Current_Benefit_Year__c FROM Account LIMIT 1];

        // Clone with Current_Benefit_Quater__c = null
        Account oldAcc = acc.clone(false);
        oldAcc.Current_Benefit_Quater__c = 'Q1';

        Account newAcc = acc.clone(false);
        newAcc.Current_Benefit_Year__c = '2026';
        newAcc.Current_Benefit_Quater__c = null;

        Map<Id, Account> oldMap = new Map<Id, Account>{ oldAcc.Id => oldAcc };
        Map<Id, Account> newMap = new Map<Id, Account>{ newAcc.Id => newAcc };

        Test.startTest();
        TierBenefitHandler.processTierChange(oldMap, newMap);
        Test.stopTest();

        List<Retailer_Benefit__c> result = [
            SELECT Id, Type__c, Benefit_Year__c
            FROM Retailer_Benefit__c
            WHERE Account__c = :acc.Id AND Status__c = 'No'
        ];

        System.assert(!result.isEmpty(), 'Expected new benefits using default quarter from today’s date');
        Boolean hasQuarterly = false;
        for (Retailer_Benefit__c rb : result) {
            if (rb.Type__c.startsWith('Q')) {
                hasQuarterly = true;
                break;
            }
        }
        System.assert(hasQuarterly, 'Should have created at least one quarterly benefit');
    }
}