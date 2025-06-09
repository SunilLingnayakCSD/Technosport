@isTest
public class customMetadataControllerTest {
    @isTest
    static void testLightningStudio() {
        // Start the test execution
        Test.startTest();
        
        // Call the method to be tested
        customMetadataController.LightningStudio();
        
        // Stop the test execution
        Test.stopTest();
        
        // Since the method is void and doesn't return anything, no assertions are needed.
        // The goal is to ensure the method is executed without errors.
    }
}