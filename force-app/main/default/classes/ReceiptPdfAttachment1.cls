public class ReceiptPdfAttachment1
 {
    @AuraEnabled
    public static void generateReceiptEstimatePdf(Id input) {
             Integer version = 1;
      List<ContentDocumentLink> existingAttachments = [SELECT ContentDocumentId, ContentDocument.Title,ContentDocument.CreatedDate  FROM ContentDocumentLink WHERE LinkedEntityId =:input AND ContentDocument.Title Like 'Invoice-%' ORDER BY ContentDocument.CreatedDate  DESC LIMIT 1];  
        System.debug('existingAttachments'+existingAttachments);
        if (!existingAttachments.isEmpty()) {
            String lastFileName = existingAttachments[0].ContentDocument.Title;
            String versionString = lastFileName.substringBetween('v', '.');
            System.debug('versionString'+versionString);
            if (versionString != null) {
                try {
                    version = Integer.valueOf(versionString) + 1;
                } catch (Exception e) {
                    version = 1;
                }
            }
        }
 
            PageReference pdfPage = Page.Invoice2;  
            pdfPage.getParameters().put('id', input); 
            Blob pdfBlob;
            try {
                pdfBlob = pdfPage.getContent();  
            } catch (VisualforceException e) {
                pdfBlob = Blob.valueOf('Error generating PDF');  
            }
          

        ContentVersion fileVersion = new ContentVersion();
fileVersion.Title ='Invoice-v' + version + '.pdf';  
fileVersion.PathOnClient = 'Invoice-v' + version + '.pdf'; 
fileVersion.VersionData = pdfBlob;  
insert fileVersion;
ContentDocumentLink docLink = new ContentDocumentLink();
docLink.ContentDocumentId= [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :fileVersion.Id LIMIT 1].ContentDocumentId;
docLink.LinkedEntityId = input; 
docLink.ShareType = 'V';  
docLink.Visibility = 'AllUsers';  
 
insert docLink;

}
 }