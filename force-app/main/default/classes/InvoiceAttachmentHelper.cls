public class InvoiceAttachmentHelper {

    @future(callout=true)
    public static void generateInvoicePDFAndAttach(Id invoiceId) {
        // Query the Invoice record to get necessary data	
        Invoice__c invoice = [SELECT Id FROM Invoice__c WHERE Id = :invoiceId LIMIT 1];

        // Generate PDF for the second Visualforce page (Second Page)
        PageReference secondPage = Page.invoice2;
        secondPage.getParameters().put('id', InvoiceId); // Pass the Invoice ID
        Blob invoicePdfBlob ;
        try{
            invoicePdfBlob=secondPage.getContentAsPDF();
        }catch(visualforceException e){
            invoicePdfBlob= Blob.valueOf('Error generating PDF');
        }
            
       // Generate PDF for the first Visualforce page (E-Way Bill)
        PageReference eWayBillPage = Page.EWayBill;
        eWayBillPage.getParameters().put('id', invoiceId); 
        Blob eWayBillPdfBlob ;
        try{
            eWayBillPdfBlob= eWayBillPage.getContentAsPDF();
        }catch(visualforceException e){
            eWayBillPdfBlob= Blob.valueOf('Error generating PDF');
        }
        
       // Create ContentVersion for Second Page PDF
        ContentVersion contentVersion2 = new ContentVersion();
        contentVersion2.Title = 'Invoice';
        contentVersion2.PathOnClient = 'Invoice_' + invoiceId + '.pdf';
        contentVersion2.VersionData = invoicePdfBlob;
        contentVersion2.FirstPublishLocationId = invoiceId; // Link to the Invoice record        
        // Create ContentVersion for E-Way Bill PDF
        ContentVersion contentVersion1 = new ContentVersion();
        contentVersion1.Title = 'E-Way Bill';
        contentVersion1.PathOnClient = 'Invoice_EWayBill_' + invoiceId + '.pdf';
        contentVersion1.VersionData = eWayBillPdfBlob;
        contentVersion1.FirstPublishLocationId = invoiceId; // Link to the Invoice record

      
        try{
        // Insert both ContentVersions (this will create ContentDocument records)
        insert new ContentVersion[] { contentVersion1, contentVersion2 };
            }
        catch(Exception e){
            HandleCustomException.LogException(e);
        }
    }
    
   

   public static void onAfterInsertOrUpdate(List<Invoice__c> records) {
        List<Invoice__Share> sharesToInsert = new List<Invoice__Share>();

        
        Set<Id> invoiceAccountIds = new Set<Id>();
        for (Invoice__c invoice : records) {
            if (invoice.Account__c != null) {
                invoiceAccountIds.add(invoice.Account__c);
                system.debug('invoiceAccountIds' +invoiceAccountIds);
            }
        }

      
        if (!invoiceAccountIds.isEmpty()) {
            List<User> communityDistributorUsers = [
                SELECT Id, Contact.AccountId 
                FROM User 
                WHERE Profile.Name = 'Community Distributor Access' 
                  AND Contact.AccountId IN :invoiceAccountIds
            ];

           system.debug('communityDistributorUsers' + communityDistributorUsers);
            for (Invoice__c invoice : records) {
               
                if (invoice.Account__c != null) {
                    
                    for (User user : communityDistributorUsers) {
                        if (user.Contact.AccountId == invoice.Account__c) {
                            Invoice__Share share = new Invoice__Share();
                            share.ParentId = invoice.Id;
                            share.UserOrGroupId = user.Id;
                            share.AccessLevel = 'Read';  
                            sharesToInsert.add(share);
                             system.debug('sharesToInsert' + sharesToInsert);
                        }
                    }
                }
            }

            // Insert share records if any need to be shared
            if (!sharesToInsert.isEmpty()) {
                insert sharesToInsert;
            }
        }
    }
}