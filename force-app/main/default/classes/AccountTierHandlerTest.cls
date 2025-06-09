@isTest
public class AccountTierHandlerTest {

    @testSetup
    static void setupTestData() {
        // Create Tier records
        List<Tier__c> tiers = new List<Tier__c>{
            new Tier__c(Name = 'Gold'),
            new Tier__c(Name = 'Silver'),
            new Tier__c(Name = 'Bronze')
        };
        insert tiers;

        // Create Account (Retailer)
        Account acc = new Account(Name = 'Retailer A',BillingPostalCode='577428', Phone='9999776677');
        insert acc;

        // Create initial Retailer_Purchase__c (with no tier data)
        Retailer_Purchase__c rp = new Retailer_Purchase__c(
            Retailer__c = acc.Id,
            Year__c = '2025'
        );
        insert rp;
    }

    @isTest
    static void testInsertContext_triggersUpdate() {
        // Get setup data
        Account acc = [SELECT Id, Retailer_Tier__c FROM Account LIMIT 1];
        Tier__c tier = [SELECT Id, Name FROM Tier__c WHERE Name = 'Gold' LIMIT 1];

        // Simulate new insert with Q1_Tier__c
        Retailer_Purchase__c newRp = new Retailer_Purchase__c(
            Retailer__c = acc.Id,
            Q1_Tier__c = tier.Name,
            Year__c = '2025'
        );

        Test.startTest();
        AccountTierHandler.handleRetailerPurchaseChanges(
            new List<Retailer_Purchase__c>{ newRp },
            null // INSERT context
        );
        Test.stopTest();

        // Assert account updated
        Account updated = [SELECT Retailer_Tier__c, Current_Benefit_Year__c, Current_Benefit_Quater__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(tier.Id, updated.Retailer_Tier__c, 'Tier should be set to Gold');
        System.assertEquals('2025', updated.Current_Benefit_Year__c);
        System.assertEquals('Q1', updated.Current_Benefit_Quater__c);
    }

    @isTest
    static void testUpdateContext_detectsQuarterChange() {
        // Get setup data
        Retailer_Purchase__c existingRp = [SELECT Id, Retailer__c,Q1_Tier__c,Q2_Tier__c,Q3_Tier__c,Q4_Tier__c FROM Retailer_Purchase__c LIMIT 1];
        Tier__c silverTier = [SELECT Id, Name FROM Tier__c WHERE Name = 'Silver' LIMIT 1];

        // Simulate update: Q2_Tier__c changed
        Retailer_Purchase__c updatedRp = new Retailer_Purchase__c(
            Id = existingRp.Id,
            Retailer__c = existingRp.Retailer__c,
            Q2_Tier__c = silverTier.Name,
            Year__c = '2026'
        );

        Test.startTest();
        AccountTierHandler.handleRetailerPurchaseChanges(
            new List<Retailer_Purchase__c>{ updatedRp },
            new Map<Id, Retailer_Purchase__c>{
                existingRp.Id => existingRp // oldMap for update
            }
        );
        Test.stopTest();

        // Assert account updated with Q2 info
        Account acc = [SELECT Retailer_Tier__c, Current_Benefit_Year__c, Current_Benefit_Quater__c FROM Account WHERE Id = :existingRp.Retailer__c];
        System.assertEquals(silverTier.Id, acc.Retailer_Tier__c, 'Tier should be set to Silver');
        System.assertEquals('2026', acc.Current_Benefit_Year__c);
        System.assertEquals('Q2', acc.Current_Benefit_Quater__c);
    }

    @isTest
    static void testUnknownTierName_skipsUpdate() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        // Pass a non-existent tier name
        Retailer_Purchase__c badRp = new Retailer_Purchase__c(
            Retailer__c = acc.Id,
            Q3_Tier__c = 'NonExistentTier',
            Year__c = '2025'
        );

        Test.startTest();
        AccountTierHandler.handleRetailerPurchaseChanges(
            new List<Retailer_Purchase__c>{ badRp },
            null
        );
        Test.stopTest();

        // Confirm no change
        Account sameAcc = [SELECT Retailer_Tier__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(null, sameAcc.Retailer_Tier__c, 'Tier should remain unchanged if tier name not found');
    }
}