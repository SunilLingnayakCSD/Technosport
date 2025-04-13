public  class FileController {

     @AuraEnabled(cacheable=true)
    public static String getFileBase64(String fileId) {
        ContentVersion cv = [SELECT VersionData FROM ContentVersion WHERE Id = :fileId LIMIT 1];
        return EncodingUtil.base64Encode(cv.VersionData);
    }

    
    @AuraEnabled(cacheable=true)
    public static List<FileData> getAllDistributorAccountFiles() {
        List<FileData> fileList = new List<FileData>();

        // Query Distributor Account records with RecordType 'Distributor'
        List<Account> distributorAccounts = [
            SELECT Id 
            FROM Account 
            WHERE RecordType.Name = 'Distributor'
        ];

        // Ensure we have Distributor Accounts to query
        if (distributorAccounts.isEmpty()) {
            return fileList; // Return empty list if no Distributor Accounts are found
        }

        // Extract the Account IDs
        List<Id> distributorAccountIds = new List<Id>();
        for (Account account : distributorAccounts) {
            distributorAccountIds.add(account.Id);
        }

        // Query Salesforce Files (ContentDocumentLink) for the Distributor Accounts using the IN operator
        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :distributorAccountIds
        ];

        // Get ContentDocumentId for each ContentDocumentLink and fetch the details from ContentVersion
        for (ContentDocumentLink link : contentDocumentLinks) {
            // Fetch ContentVersion related to the ContentDocumentId
            List<ContentVersion> contentVersions = [
                SELECT Id, Title, ContentDocumentId, FileExtension 
                FROM ContentVersion 
                WHERE ContentDocumentId = :link.ContentDocumentId 
                LIMIT 1
            ];
            if (!contentVersions.isEmpty()) {
                ContentVersion version = contentVersions[0];
                fileList.add(new FileData(
                    version.ContentDocumentId, 
                    version.Title, 
                    '/sfc/servlet.shepherd/version/download/' + version.Id,
                    version.FileExtension // Added file extension here
                ));
            }
        }

        // Query legacy Attachments for Distributor Accounts using the IN operator
        List<Attachment> attachments = [
            SELECT Id, Name, ParentId
            FROM Attachment
            WHERE ParentId IN :distributorAccountIds
        ];

        // Add legacy Attachments to the list
        for (Attachment attachment : attachments) {
            fileList.add(new FileData(attachment.Id, attachment.Name, '/servlet/servlet.FileDownload?file=' + attachment.Id, '')); // File extension is not available for Attachments
        }

        return fileList;
    }

    // Wrapper class to return file information
    public class FileData {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String url;
        @AuraEnabled public String fileExtension; // File extension property

        public FileData(String id, String name, String url, String fileExtension) {
            this.id = id;
            this.name = name;
            this.url = url;
            this.fileExtension = fileExtension; // Set file extension
        }
    }
    
@AuraEnabled
public static void deleteFile(String fileId) {
    try {
        // Query ContentDocumentLink to check if it's linked to any records
        List<ContentDocumentLink> docLinks = [
            SELECT Id, LinkedEntityId, ContentDocumentId
            FROM ContentDocumentLink 
            WHERE ContentDocumentId = :fileId
        ];
        
        // Collect all unique ContentDocumentId values (although we expect only one)
        Set<Id> documentIds = new Set<Id>();
        for (ContentDocumentLink cdLink : docLinks) {
            documentIds.add(cdLink.ContentDocumentId); // Ensure unique ContentDocumentId
        }

        // If the file is linked to records, delete the links first
        if (!docLinks.isEmpty()) {
            delete docLinks; // Unlink the file from the records
        }

        // Now, try deleting the ContentDocument itself if it exists
        List<ContentDocument> contentDocs = [
            SELECT Id
            FROM ContentDocument 
            WHERE Id =:fileId
        ];

        if (!contentDocs.isEmpty()) {
            delete contentDocs; // Delete the content document
        }

    } catch (DmlException e) {
        // Handle DML errors
        System.debug('Error deleting file: ' + e.getMessage());
        throw new AuraHandledException('Error deleting the file: ' + e.getMessage());
    } catch (Exception e) {
        // Handle any other unexpected errors
        System.debug('Unexpected error occurred: ' + e.getMessage());
        throw new AuraHandledException('Unexpected error occurred: ' + e.getMessage());
    }
}


}