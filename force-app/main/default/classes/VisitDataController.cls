public with sharing class VisitDataController {

    @AuraEnabled(cacheable=true)
    public static Map<String, List<cgcloud__Visit_Job__c>> getVisitJobQuestions(Id visitId) {
        try {
            // Debugging the input visitId parameter
            System.debug('Fetching Visit Job questions for Visit ID: ' + visitId);
            
            if (visitId == null) {
                throw new AuraHandledException('Visit ID is null or undefined.');
            }
            
            // Query the VisitJob records related to the visitId
            List<cgcloud__Visit_Job__c> visitJobs = [
                SELECT Id, 
                       Question_Name__c,
                       cgcloud__Visit__c,
                       cgcloud__Display_Value__c,
                       Job_Definition__c
                FROM cgcloud__Visit_Job__c
                WHERE cgcloud__Visit__c = :visitId
            ];
            
            // Separate questions and surveys into different lists
            List<cgcloud__Visit_Job__c> questions = new List<cgcloud__Visit_Job__c>();
            List<cgcloud__Visit_Job__c> surveys = new List<cgcloud__Visit_Job__c>();
            
            for (cgcloud__Visit_Job__c job : visitJobs) {
                if (job.Job_Definition__c == 'Question') {
                    questions.add(job);
                } else if (job.Job_Definition__c == 'Survey') {
                    surveys.add(job);
                }
            }
            
            // Return both lists in a map
            Map<String, List<cgcloud__Visit_Job__c>> result = new Map<String, List<cgcloud__Visit_Job__c>>();
            result.put('questions', questions);
            result.put('surveys', surveys);
            
            return result;
            
        } catch (Exception e) {
            System.debug('Error occurred: ' + e.getMessage());
            throw new AuraHandledException('Error occurred while fetching visit job questions.');
        }
    }
}