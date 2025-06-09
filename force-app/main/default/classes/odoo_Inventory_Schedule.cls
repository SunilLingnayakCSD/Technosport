global with sharing class odoo_Inventory_Schedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        Odoo_Inventory_Batch batchJob = new Odoo_Inventory_Batch();
        Database.executeBatch(batchJob, 200);
       // System.enqueueJob(new Odoo_Inventory_Queueable());
        System.debug('Scheduled Odoo Inventory Batch job has been executed.');
    }
}