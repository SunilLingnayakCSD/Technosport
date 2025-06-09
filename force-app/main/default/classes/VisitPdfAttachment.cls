public with sharing class VisitPdfAttachment {

    @AuraEnabled
    public static Boolean generateVisitPdf(Id visitId) {
        if (visitId == null) {
            throw new AuraHandledException('Visit Id is required');
        }

        // Find latest Order related to Visit
        List<Order> orders = [
            SELECT Id, OrderNumber 
            FROM Order
            WHERE Visit__c = :visitId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (orders.isEmpty()) {
            // No order found — signal to LWC gracefully
            return false;
        }

        Order order = orders[0];

        // Versioning existing files attached to the Visit
        Integer version = 1;
        List<ContentDocumentLink> existingFiles = [
            SELECT ContentDocument.Title 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :visitId AND ContentDocument.Title LIKE 'Order-v%.pdf'
            ORDER BY ContentDocument.CreatedDate DESC 
            LIMIT 1
        ];

        if (!existingFiles.isEmpty()) {
            String lastTitle = existingFiles[0].ContentDocument.Title;
            Integer startIdx = lastTitle.indexOf('v') + 1;
            Integer endIdx = lastTitle.lastIndexOf('.');
            if (startIdx > 0 && endIdx > startIdx) {
                String verStr = lastTitle.substring(startIdx, endIdx);
                try {
                    version = Integer.valueOf(verStr) + 1;
                } catch (Exception e) {
                    version = 1;
                }
            }
        }

        // Generate PDF blob from VF page
        PageReference pdfPage = Page.OrderPdfGenerator;  
        pdfPage.getParameters().put('visitId', visitId);
        // In generateVisitPdf method, replace the PDF generation block with:
Blob pdfBlob;
if (Test.isRunningTest()) {
    // Generate mock PDF in test context
    pdfBlob = Blob.valueOf('Test PDF Content');
} else {
    try {
        pdfBlob = pdfPage.getContentAsPDF();
    } catch (Exception e) {
        throw new AuraHandledException('Error generating PDF: ' + e.getMessage());
    }
}

        // Insert ContentVersion with PDF
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Invoice-v' + version + '.pdf';
        cv.PathOnClient = cv.Title;
        cv.VersionData = pdfBlob;
        insert cv;

        // Link ContentDocument to Visit
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [
            SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id
        ].ContentDocumentId;
        cdl.LinkedEntityId = visitId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;

        return true;
    }
}