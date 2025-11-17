/**
 * @Name         AFGetNPSSurveysAction
 * @Author       Agentforce Implementation Team
 * @Date         2025-01-15
 * @Description  Invocable Apex class to retrieve NPS surveys with optional status filtering.
 *               Used by GenAI functions to provide survey data to Agentforce.
 */
public with sharing class AFGetNPSSurveysAction {

    /**
     * Input wrapper for invocable method
     */
    public class SurveyRequest {
        @InvocableVariable(label='Status Filter' required=false)
        public String statusFilter;
        
        @InvocableVariable(label='User ID' required=false)
        public Id userId;
    }

    /**
     * Response wrapper for invocable method - contains list of surveys
     */
    public class SurveyResponse {
        @AuraEnabled @InvocableVariable
        public NPSSurveyList availableSurveys;
    }

    /**
     * Output wrapper for invocable method - contains list of surveys
     */
    public class NPSSurveyList {
        @AuraEnabled @InvocableVariable
        public List<NPSSurveyItem> surveys;
    }

    /**
     * Individual survey item wrapper
     */
    public class NPSSurveyItem {
        @AuraEnabled
        public String id;
        
        @AuraEnabled
        public String name;
        
        @AuraEnabled
        public String status;
        
        @AuraEnabled
        public String accountName;
        
        @AuraEnabled
        public Date surveyDate;
        
        @AuraEnabled
        public String contactName;
        
        @AuraEnabled
        public String ownerName;
        
        @AuraEnabled
        public Decimal totalNPSScore;
        
        @AuraEnabled
        public Decimal averageScore;
    }

    /**
     * Retrieves NPS surveys with optional status filtering
     * @param requests List of SurveyRequest objects
     * @return List of SurveyResponse containing survey data
     */
    @InvocableMethod(label='Get NPS Surveys' description='Retrieves NPS surveys with optional status filter')
    public static List<SurveyResponse> getSurveys(List<SurveyRequest> requests) {
        List<SurveyResponse> results = new List<SurveyResponse>();
        
        if (requests == null || requests.isEmpty()) {
            SurveyResponse emptyResponse = new SurveyResponse();
            emptyResponse.availableSurveys = new NPSSurveyList();
            emptyResponse.availableSurveys.surveys = new List<NPSSurveyItem>();
            results.add(emptyResponse);
            return results;
        }
        
        SurveyRequest request = requests[0];
        String statusFilter = request != null ? request.statusFilter : null;
        
        // Build the SOQL query
        String query = 'SELECT Id, Name, Status__c, Account__r.Name, Survey_Sent_Date__c, ' +
                       'NPS_Contact__r.Name, Owner.Name, Total_NPS_Score__c, Average_Score__c ' +
                       'FROM NPS__c ';
        
        // Apply status filter if provided and equals "Closed"
        if (String.isNotBlank(statusFilter) && statusFilter.equalsIgnoreCase('Closed')) {
            query += 'WHERE Status__c = \'Closed\' ';
        }
        
        query += 'ORDER BY CreatedDate DESC LIMIT 100';
        
        try {
            List<NPS__c> npsRecords = Database.query(query);
            List<NPSSurveyItem> surveyItems = new List<NPSSurveyItem>();
            
            for (NPS__c nps : npsRecords) {
                NPSSurveyItem item = new NPSSurveyItem();
                item.id = nps.Id;
                item.name = nps.Name;
                item.status = nps.Status__c;
                item.accountName = nps.Account__r != null ? nps.Account__r.Name : null;
                item.surveyDate = nps.Survey_Sent_Date__c;
                item.contactName = nps.NPS_Contact__r != null ? nps.NPS_Contact__r.Name : null;
                item.ownerName = nps.Owner != null ? nps.Owner.Name : null;
                item.totalNPSScore = nps.Total_NPS_Score__c;
                item.averageScore = nps.Average_Score__c;
                
                surveyItems.add(item);
            }
            
            NPSSurveyList surveyList = new NPSSurveyList();
            surveyList.surveys = surveyItems;
            
            SurveyResponse response = new SurveyResponse();
            response.availableSurveys = surveyList;
            results.add(response);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error retrieving NPS surveys: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            // Return empty response on error
            SurveyResponse errorResponse = new SurveyResponse();
            errorResponse.availableSurveys = new NPSSurveyList();
            errorResponse.availableSurveys.surveys = new List<NPSSurveyItem>();
            results.add(errorResponse);
        }
        
        return results;
    }
}

