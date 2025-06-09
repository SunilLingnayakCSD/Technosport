public class DeleteOldProductVideosSchedule  implements Schedulable {
    public void execute(SchedulableContext sc) {
        DeleteOldProductVideosBatch batch = new DeleteOldProductVideosBatch();
        Database.executeBatch(batch, 200);  
    }

}