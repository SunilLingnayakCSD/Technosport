@isTest
public class UpdateProductGoogleDriveTest {
    
    @isTest
    static void testTriggerWithImageFile() {
        
        // ✅ Create a Product Template record (if required)
        cgcloud__Product_Template__c temp = new cgcloud__Product_Template__c(
            Name = 'Sample template',
            cgcloud__Sales_Org__c = '0001',
            cgcloud__Description_Language_1__c = 'Sample'
        );
        insert temp;

        // ✅ Create a Product2 record
        Product2 prod = new Product2(
            Name = 'Test Product',
            cgcloud__Product_Template__c = temp.Id,
            cgcloud__Product_Level__c = 'Product',
            cgcloud__Description_1_Language_1__c = 'Sample'
        );
        insert prod;

        // ✅ Create a ContentVersion (associated with ContentDocument)
        ContentVersion cv = new ContentVersion(
            Title = 'Test Image',
            PathOnClient = 'TestImage.jpg',
            VersionData = Blob.valueOf('Test file content'), // Simulating file content
            FirstPublishLocationId = prod.Id
        );
        insert cv;

        // ✅ Query ContentDocument Id after insertion
        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id LIMIT 1];

        // ✅ Query the automatically created ContentDocumentLink
        ContentDocumentLink cdl = [SELECT Id, LinkedEntityId, ContentDocumentId, Visibility
                                    FROM ContentDocumentLink
                                    WHERE LinkedEntityId = :prod.Id
                                    AND ContentDocumentId = :cd.Id
                                    LIMIT 1];

        // ✅ Validate that Image_url__c and URL__c are updated
        Product2 updatedProd = [SELECT Id, Image_url__c, URL__c FROM Product2 WHERE Id = :prod.Id];
        System.assertNotEquals(null, updatedProd.Image_url__c, 'Image URL should be populated.');
        System.assertNotEquals(null, updatedProd.URL__c, 'Org URL should be populated.');
        System.assert(updatedProd.Image_url__c.contains(cd.Id), 'Image URL should contain the ContentDocumentId.');
        System.assert(updatedProd.URL__c.contains(cd.Id), 'Org URL should contain the ContentDocumentId.');
    }

    @isTest
    static void testTriggerWithVideoFile() {
        // ✅ Create a Product2 record
        Product2 prod = new Product2(
            Name = 'Test Video Product'
        );
        insert prod;

        // ✅ Create a ContentVersion for a video file
        ContentVersion cv = new ContentVersion(
            Title = 'Test Video',
            PathOnClient = 'TestVideo.mp4',
            VersionData = Blob.valueOf('Test video content'), // Simulating file content
            FirstPublishLocationId = prod.Id
        );
        insert cv;

        // ✅ Query ContentDocument Id after insertion
        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id LIMIT 1];

        // ✅ Query the automatically created ContentDocumentLink
        ContentDocumentLink cdl = [SELECT Id FROM ContentDocumentLink
                                    WHERE LinkedEntityId = :prod.Id
                                    AND ContentDocumentId = :cd.Id
                                    LIMIT 1];

        // ✅ Validate that Video_Url__c is updated
        Product2 updatedProd = [SELECT Id, Video_Url__c FROM Product2 WHERE Id = :prod.Id];
        System.assertNotEquals(null, updatedProd.Video_Url__c, 'Video URL should be populated.');
        System.assert(updatedProd.Video_Url__c.contains(cd.Id), 'Video URL should contain the ContentDocumentId.');
    }

    @isTest
    static void testTriggerWithNonVideoOrImageFile() {
        // ✅ Create a Product2 record
        Product2 prod = new Product2(
            Name = 'Test Unknown File Product'
        );
        insert prod;

        // ✅ Create a ContentVersion for a non-video/image file
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Test document content'), // Simulating file content
            FirstPublishLocationId = prod.Id
        );
        insert cv;

        // ✅ Query ContentDocument Id after insertion
        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id LIMIT 1];

        // ✅ Query the automatically created ContentDocumentLink
        ContentDocumentLink cdl = [SELECT Id FROM ContentDocumentLink
                                    WHERE LinkedEntityId = :prod.Id
                                    AND ContentDocumentId = :cd.Id
                                    LIMIT 1];

        // ✅ Validate that neither Video_Url__c nor Image_url__c is updated
        Product2 updatedProd = [SELECT Id, Video_Url__c, Image_url__c, URL__c FROM Product2 WHERE Id = :prod.Id];
        System.assertEquals(null, updatedProd.Video_Url__c, 'Video URL should not be populated for non-video files.');
        System.assertNotEquals(null, updatedProd.Image_url__c, 'Image URL should be populated.');
        System.assertNotEquals(null, updatedProd.URL__c, 'Org URL should be populated.');
    }

    @isTest
    static void testBeforeInsertVisibility() {
        // ✅ Create a Product2 record
        Product2 prod = new Product2(Name = 'Test Product Visibility');
        insert prod;

        // ✅ Create a ContentVersion for an image
        ContentVersion cv = new ContentVersion(
            Title = 'Test Image',
            PathOnClient = 'TestImage.jpg',
            VersionData = Blob.valueOf('Test file content'),
            FirstPublishLocationId = prod.Id
        );
        insert cv;

        // ✅ Query ContentDocument Id after insertion
        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id LIMIT 1];

        // ✅ Query the automatically created ContentDocumentLink
        ContentDocumentLink cdl = [SELECT Id, Visibility FROM ContentDocumentLink
                                    WHERE LinkedEntityId = :prod.Id
                                    AND ContentDocumentId = :cd.Id
                                    LIMIT 1];

        // ✅ Validate that visibility is set correctly
        System.assertEquals('AllUsers', cdl.Visibility, 'Visibility should be set to AllUsers.');
    }
}