@IsTest
public class AttendanceControllerTest {
    
    @IsTest
    static void testGetCheckedAttendances() {
        // Create test user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User testUser = new User(
            Alias = 'testu',
            Email = 'testuser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser@testorg.com'
        );
        insert testUser;
        
        // Create test attendances (without setting Name field)
        List<Attendance__c> testAttendances = new List<Attendance__c>();
        for(Integer i=0; i<5; i++) {
            testAttendances.add(new Attendance__c(
                Is_Checked_In__c = true,
                Check_In__c = System.now().addHours(-i),
                OwnerId = testUser.Id
            ));
        }
        insert testAttendances;
        
        Test.startTest();
        List<Attendance__c> attendances = AttendanceController.getCheckedAttendances(testUser.Id);
        Test.stopTest();
        
        // Verify results
        System.assertEquals(5, attendances.size(), 'Should return all attendances for the user');
        for(Attendance__c att : attendances) {
            System.assertEquals(testUser.Id, att.OwnerId, 'Attendance should belong to test user');
            System.assertEquals(true, att.Is_Checked_In__c, 'Attendance should be checked in');
            System.assertNotEquals(null, att.Check_In__c, 'Check-in time should be set');
        }
        
        // Verify sorting by CreatedDate DESC
        DateTime previousDate = DateTime.now();
        for(Attendance__c att : attendances) {
            System.assert(att.CreatedDate <= previousDate, 'Attendances should be sorted by CreatedDate DESC');
            previousDate = att.CreatedDate;
        }
    }
    
    @IsTest
    static void testGetCheckedAttendances_NoResults() {
        // Create test user with no attendances
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User emptyUser = new User(
            Alias = 'emptyu',
            Email = 'emptyuser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Empty',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'emptyuser@testorg.com'
        );
        insert emptyUser;
        
        Test.startTest();
        List<Attendance__c> attendances = AttendanceController.getCheckedAttendances(emptyUser.Id);
        Test.stopTest();
        
        System.assertEquals(0, attendances.size(), 'Should return empty list for user with no attendances');
    }
    
}