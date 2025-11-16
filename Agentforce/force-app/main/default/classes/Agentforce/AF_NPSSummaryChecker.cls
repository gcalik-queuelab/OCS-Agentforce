/**
 * @Name         AF_NPSSummaryChecker
 * @Author       Agentforce Implementation Team
 * @Date         2025-01-15
 * @Description  Invocable Apex class to check if an NPS Survey Summary already exists.
 */
public with sharing class AF_NPSSummaryChecker {

    /**
     * Input wrapper for invocable method
     */
    public class SummaryRequest {
        @InvocableVariable(label='NPS Survey ID' required=true)
        public Id npsId;
    }

    /**
     * Output wrapper for invocable method
     */
    public class SummaryResponse {
        @InvocableVariable
        public Boolean success;
        
        @InvocableVariable
        public String message;
        
        @InvocableVariable
        public Boolean hasExistingSummary;
    }

    /**
     * Checks if an existing summary exists for the given NPS survey (AuraEnabled for LWC)
     * @param npsId NPS Survey ID
     * @return SummaryResponse indicating if summary exists
     */
    @AuraEnabled(cacheable=false)
    public static SummaryResponse checkForExistingSummary(Id npsId) {
        SummaryResponse response = new SummaryResponse();
        
        try {
            // Query for existing summaries
            List<NPS_Survey_Summary__c> existingSummaries = [
                SELECT Id, Name, Summary_Generation_Date__c
                FROM NPS_Survey_Summary__c
                WHERE NPS_Survey__c = :npsId
                LIMIT 1
            ];

            response.hasExistingSummary = !existingSummaries.isEmpty();
            response.success = true;
            response.message = existingSummaries.isEmpty() 
                ? 'No existing summary found' 
                : 'Existing summary found: ' + existingSummaries[0].Name;

        } catch (Exception e) {
            response.success = false;
            response.message = 'Error checking for existing summary: ' + e.getMessage();
            response.hasExistingSummary = false;
            System.debug(LoggingLevel.ERROR, 'AF_NPSSummaryChecker.checkForExistingSummary error: ' + e.getMessage());
        }

        return response;
    }

    /**
     * Checks if an existing summary exists for the given NPS survey (Invocable for Flow)
     * @param requests List of SummaryRequest containing NPS IDs
     * @return List of SummaryResponse indicating if summary exists
     */
    @InvocableMethod(label='Check for Existing NPS Summary' description='Checks if an NPS Survey Summary already exists for the given NPS survey')
    public static List<SummaryResponse> checkForExistingSummaryInvocable(List<SummaryRequest> requests) {
        List<SummaryResponse> responses = new List<SummaryResponse>();

        for (SummaryRequest request : requests) {
            responses.add(checkForExistingSummary(request.npsId));
        }

        return responses;
    }
}

