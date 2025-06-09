import { LightningElement, track, wire } from 'lwc';
import getAllDistributorAccountFiles from '@salesforce/apex/FileController.getAllDistributorAccountFiles';
import deleteFile from '@salesforce/apex/FileController.deleteFile'; // Add Apex method to delete file
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class FileList extends LightningElement {
    @track files = [];

    // Fetch files using the Apex wire service
    @wire(getAllDistributorAccountFiles)
    wiredFiles({ error, data }) {
        if (data) {
            this.files = data;
        } else if (error) {
            console.error('Error fetching files', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'There was an error loading files',
                    variant: 'error',
                })
            );
        }
    }

    // Handle delete button click
    handleDelete(event) {
        const fileId = event.target.dataset.id;

        // Call the Apex deleteFile method
        deleteFile({ fileId: fileId })
            .then(() => {
                // Remove the deleted file from the list
                this.files = this.files.filter(file => file.id !== fileId);

                // Show success message
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'File deleted successfully',
                        variant: 'success',
                    })
                );
            })
            .catch(error => {
                console.error('Error deleting file', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'There was an error deleting the file',
                        variant: 'error',
                    })
                );
            });
    }
}