import { LightningElement, wire } from 'lwc';
import getAllAttachments from '@salesforce/apex/FileController.getAllDistributorAccountFiles';
import communityPath from '@salesforce/community/basePath';
import { NavigationMixin } from "lightning/navigation";
export default class FilePreviewDownload extends LightningElement {
    allAttachments = []; // Holds all attachments
    fileToPreview;
    error;
    showModal = false;

    // Wire method to get all attachments for Distributor accounts
    @wire(getAllAttachments)
    wiredAttachments({ data, error }) {
        if (data) {
            console.log('Data from Apex:', data); // Log the raw data to inspect its structure
            
            // Ensure that we clone the data to avoid Proxy issues
            this.allAttachments = data.map(file => ({
                label: file.name,  // Extracting the file name
                value: file.id,    // Extracting the file ID
                url: `${communityPath}/sfsites/c/sfc/servlet.shepherd/document/download/${file.id}`+'#toolbar=0&navpanes=0',//file.url,     // Extracting the file download URL
                fileExtension: file.fileExtension  // Extracting file extension
            }));

            console.log('All Attachments:', this.allAttachments);  // Log the formatted data
        } else if (error) {
            this.error = error.body.message;  // Handle any errors that occur during the query
            console.log(this.error);
        }
    }

    // Preview handler - Handles the preview button click
    previewHandler(event) {
        const fileId = event.target.dataset.id;
        console.log('Preview file with ID:', fileId);

        // Find the selected file by ID
        this.fileToPreview = this.allAttachments.find(file => file.value === fileId);

        // Log the preview file object to see its contents
        console.log('File to preview:', this.fileToPreview);

        if (this.fileToPreview) {
            this.showModal = true; // Show the modal if the file is found
            console.log('Opening modal with file:',  this.showModal);
            console.log('File to preview:', this.fileToPreview); // Display the file object in the console
            console.log('File Name:', this.fileToPreview.label);  // Display just the file name
            console.log('File ID:', this.fileToPreview.value);    // Display just the file ID
            console.log('File URL:', this.fileToPreview.url);     // Display the file URL // Confirm the modal will open with the correct file
        } else {
            console.log('File not found for preview:', fileId); // If file is not found
        }
    }

    // Close modal
    closeModal() {
        this.showModal = false;
    }

    // Check if the file is an image
    get isImage() {
        const ext = this.fileToPreview ? this.fileToPreview.fileExtension : ''; // Corrected to reference 'fileExtension'
        console.log('File Extension for image check:', ext);
        return ['jpg', 'jpeg', 'png', 'gif', 'bmp'].includes(ext);
    }

    // Check if the file is a PDF
    get isPdf() {
        const ext = this.fileToPreview ? this.fileToPreview.fileExtension : ''; // Corrected to reference 'fileExtension'
        return ext === 'pdf';
    }

    // Check if the file is a Word document
    get isWord() {
        const ext = this.fileToPreview ? this.fileToPreview.fileExtension : ''; // Corrected to reference 'fileExtension'
        return ['doc', 'docx'].includes(ext);
    }

    // Check if the file is an Excel document
    get isExcel() {
        const ext = this.fileToPreview ? this.fileToPreview.fileExtension : ''; // Corrected to reference 'fileExtension'
        return ['xls', 'xlsx','csv'].includes(ext);
    }

    get filesURL(){
        let fileUrl = 'https://speed-ruby-8553--devsandbox.sandbox.my.site.com/'+this.fileToPreview.url;
        //return 'https://docs.google.com/viewer?url='+this.fileToPreview.url;
        return `https://view.officeapps.live.com/op/view.aspx?src=${encodeURIComponent(fileUrl)}`;
        //return `https://docs.google.com/gview?url=${encodeURIComponent(fileUrl)}&embedded=true`;
        //return 'https://view.officeapps.live.com/op/view.aspx?src='+this.fileToPreview.url;
    }

    // Method to download the file
    downloadHandler(event) {
        const fileId = event.target.dataset.id; // Get the file ID from the button click
          
        // Construct the download URL using window.location.origin to ensure the correct domain
        const completeDownloadUrl =  `${communityPath}/sfsites/c/sfc/servlet.shepherd/document/download/${fileId}`;//`${window.location.origin}/sfc/servlet.shepherd/version/download/${fileId}`;
        
        // Log the URL to ensure it's correct
        console.log('Complete download URL:', completeDownloadUrl);

        // Create a temporary anchor element (<a>) to trigger the download
        const downloadLink = document.createElement('a');
        downloadLink.href = completeDownloadUrl; // Set the complete URL for the download
        downloadLink.download = fileId; // Optional: set the file ID as the download file name

        // Append the link to the body, trigger the download, then remove it
        document.body.appendChild(downloadLink);
        downloadLink.click();
        document.body.removeChild(downloadLink); // Clean up after download
}

}