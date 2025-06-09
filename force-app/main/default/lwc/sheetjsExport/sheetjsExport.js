import { LightningElement } from 'lwc';
import SheetJS from '@salesforce/resourceUrl/SheetJs'; // The static resource for SheetJS
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';

export default class SheetjsExport extends LightningElement {

    async connectedCallback() {
        await loadScript(this, SheetJS); // load the library
        // At this point, the library is accessible with the `XLSX` variable
        this.version = XLSX.version;
        console.log('version: '+this.version);      
    }
  exportToExcel() {
    // Sample table data for demonstration purposes
    const tableData = [
      ['John Doe', 30, 'john.doe@example.com'],
      ['Jane Smith', 28, 'jane.smith@example.com'],
      ['Michael Johnson', 35, 'michael.johnson@example.com'],
      // Add more data as needed
    ];

    const filename = 'ExportToExcel.xlsx';
    const workbook = XLSX.utils.book_new();
    const headers = [];
    const worksheetData = [];

    for (const record of tableData) {
        worksheetData.push({
            "Name": record[0],
            "Age": record[1],
            "Email":record[2]
           
        });
    }
    const worksheet = XLSX.utils.json_to_sheet(worksheetData, { header: headers });
    XLSX.utils.book_append_sheet(workbook, worksheet, 'ExportToExcel');

    const excelBuffer = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
    const blob = new Blob([excelBuffer], { type: 'application/octet-stream' });

    // Create a download link and click it programmatically to initiate the download
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = filename;
    a.click();
    // Release the object URL to free up memory
    URL.revokeObjectURL(a.href);
    }
}