/**
 * @Name         AF_NPSSummaryCreator
 * @Author       Agentforce Implementation Team
 * @Date         2025-01-15
 * @Description  Invocable Apex class to manually trigger AI summary creation for NPS surveys.
 *               Provides methods to check for existing summaries and create new ones.
 */
public with sharing class AF_NPSSummaryCreator {

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
        @AuraEnabled @InvocableVariable
        public Boolean success;
        
        @AuraEnabled @InvocableVariable
        public String message;
        
        @AuraEnabled @InvocableVariable
        public Boolean hasExistingSummary;
    }

    /**
     * Creates or re-creates an AI summary for the given NPS survey (AuraEnabled for LWC)
     * If a summary exists, it will be deleted first
     * @param npsId NPS Survey ID
     * @return SummaryResponse indicating success/failure
     */
    @AuraEnabled
    public static SummaryResponse createSummary(Id npsId) {
        SummaryResponse response = new SummaryResponse();
        
        try {
            // Query the NPS record
            List<NPS__c> npsRecords = [
                SELECT Id, Name, Status__c, Account__c
                FROM NPS__c
                WHERE Id = :npsId
                LIMIT 1
            ];

            if (npsRecords.isEmpty()) {
                response.success = false;
                response.message = 'NPS Survey not found';
                return response;
            }

            NPS__c nps = npsRecords[0];

            // Validate status
            if (nps.Status__c != 'Closed') {
                response.success = false;
                response.message = 'Summary can only be created for NPS surveys with Status = Closed';
                return response;
            }

            // Delete existing summaries if any
            List<NPS_Survey_Summary__c> existingSummaries = [
                SELECT Id
                FROM NPS_Survey_Summary__c
                WHERE NPS_Survey__c = :npsId
            ];

            if (!existingSummaries.isEmpty()) {
                delete existingSummaries;
                System.debug('AF_NPSSummaryCreator: Deleted ' + existingSummaries.size() + ' existing summary(ies)');
            }

            // Query NPS responses
            List<NPS_Response__c> responsesList = queryNPSResponses(new Set<Id>{ npsId });

            // Validate required data
            if (!AF_NPSPromptBuilder.hasRequiredData(nps, responsesList)) {
                response.success = false;
                response.message = 'NPS survey does not have required data for summary generation (must have responses and be Closed)';
                return response;
            }

            // Group responses by NPS Id
            Map<Id, List<NPS_Response__c>> npsResponsesMap = groupResponsesByNPS(responsesList);

            // Enqueue the summary generation job
            System.enqueueJob(new AF_NPSAISummaryQueueable(npsResponsesMap, new Set<Id>{ npsId }));

            response.success = true;
            response.message = 'Summary creation job has been queued. The summary will be generated shortly.';
            response.hasExistingSummary = false;

        } catch (Exception e) {
            response.success = false;
            response.message = 'Error creating summary: ' + e.getMessage();
            response.hasExistingSummary = false;
            System.debug(LoggingLevel.ERROR, 'AF_NPSSummaryCreator.createSummary error: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
        }

        return response;
    }

    /**
     * Creates or re-creates an AI summary for the given NPS survey (Invocable for Flow)
     * If a summary exists, it will be deleted first
     * @param requests List of SummaryRequest containing NPS IDs
     * @return List of SummaryResponse indicating success/failure
     */
    @InvocableMethod(label='Create NPS Summary' description='Creates or re-creates an AI-generated summary for an NPS survey. Deletes existing summary if present.')
    public static List<SummaryResponse> createSummaryInvocable(List<SummaryRequest> requests) {
        List<SummaryResponse> responses = new List<SummaryResponse>();

        for (SummaryRequest request : requests) {
            responses.add(createSummary(request.npsId));
        }

        return responses;
    }

    /**
     * Queries all NPS Response records for given NPS Ids
     * Reuses logic from AF_NPSTriggerHandler
     * @param npsIds Set of NPS Ids
     * @return List of NPS_Response__c records
     */
    private static List<NPS_Response__c> queryNPSResponses(Set<Id> npsIds) {
        return [
            SELECT Id, NPS__c, Name,
                   Question__c, Question_Text__c, Question_ID__c,
                   Score__c, Answer__c,
                   Suggestion_for_improvement__c,
                   Order__c, Overall_Comments__c
            FROM NPS_Response__c
            WHERE NPS__c IN :npsIds
            ORDER BY NPS__c, Order__c NULLS LAST
        ];
    }

    /**
     * Groups NPS responses by their parent NPS record Id
     * Reuses logic from AF_NPSTriggerHandler
     * @param responses List of all responses
     * @return Map of NPS Id to List of its responses
     */
    private static Map<Id, List<NPS_Response__c>> groupResponsesByNPS(List<NPS_Response__c> responses) {
        Map<Id, List<NPS_Response__c>> npsResponsesMap = new Map<Id, List<NPS_Response__c>>();

        for (NPS_Response__c response : responses) {
            if (!npsResponsesMap.containsKey(response.NPS__c)) {
                npsResponsesMap.put(response.NPS__c, new List<NPS_Response__c>());
            }
            npsResponsesMap.get(response.NPS__c).add(response);
        }

        return npsResponsesMap;
    }
}

