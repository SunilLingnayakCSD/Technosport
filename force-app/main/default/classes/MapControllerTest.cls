@isTest
private class MapControllerTest {
    
      @isTest
    static void testGetLocation() {
        // Create test Attendance__c record
        Attendance__c att = new Attendance__c(
            Latitude__c = '12.3456',
            Longitude__c = '65.4321'
        );
        insert att;

        Test.startTest();
        List<Attendance__c> result = invoicepopupController.getLocation(att.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should return one Attendance__c record');
        System.assertEquals(att.Latitude__c, result[0].Latitude__c, 'Latitude should match');
        System.assertEquals(att.Longitude__c, result[0].Longitude__c, 'Longitude should match');
    }

    @isTest
static void testGetVisitLocation() {
    // Create a required related record if PlaceId is a lookup (e.g., Account or Place__c)
    // Replace with actual object if different
    Account acc = new Account(
            Name = 'Test Account',
            BillingStreet = '123 Test St',
            BillingCity = 'Test City',
            BillingPostalCode = '12345');
    insert acc;
    
    RetailStore store = new RetailStore(Name = 'Test Store', AccountId = acc.Id);
        insert store;

    // Create test Visit record with required fields
    Visit visit = new Visit(
        AccountId = acc.Id, // assuming PlaceId is a lookup to Account or similar
        PlaceId = store.Id,
        PlannedVisitStartTime = System.today(),
        Latitude__c = '23.4567',
        Longitude__c = '76.5432'
    );
    insert visit;

    Test.startTest();
    List<Visit> result = invoicepopupController.getvisitLocation(visit.Id);
    Test.stopTest();

    System.assertNotEquals(null, result, 'Result should not be null');
    System.assertEquals(1, result.size(), 'Should return one Visit record');
    System.assertEquals(visit.Latitude__c, result[0].Latitude__c, 'Latitude should match');
    System.assertEquals(visit.Longitude__c, result[0].Longitude__c, 'Longitude should match');
}

}