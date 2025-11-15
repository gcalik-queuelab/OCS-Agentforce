/**
 * @Name         AF_NPSTriggerHandler
 * @Author       Agentforce Implementation Team
 * @Date         2025-01-15
 * @Description  Handler class for AF_NPSTrigger. Manages the business logic for NPS trigger events,
 *               specifically detecting when NPS surveys are marked as "Closed" and initiating
 *               AI summary generation via Agentforce.
 */
public with sharing class AF_NPSTriggerHandler {

    /**
     * Handles after update trigger logic for NPS__c
     * Detects status changes to "Closed" and initiates async AI summary generation
     * @param newList List of updated NPS records (Trigger.new)
     * @param oldMap Map of old NPS records before update (Trigger.oldMap)
     */
    public static void handleAfterUpdate(List<NPS__c> newList, Map<Id, NPS__c> oldMap) {
        Set<Id> closedNPSIds = new Set<Id>();

        // Identify NPS records that just changed to Closed status
        for (NPS__c nps : newList) {
            NPS__c oldNPS = oldMap.get(nps.Id);

            // Check if Status changed from non-Closed to Closed
            if (nps.Status__c == 'Closed' && oldNPS.Status__c != 'Closed') {
                closedNPSIds.add(nps.Id);
            }
        }

        // If we have newly closed surveys, generate AI summaries
        if (!closedNPSIds.isEmpty()) {
            System.debug('AF_NPSTriggerHandler: Found ' + closedNPSIds.size() + ' newly closed NPS surveys');
            generateAISummariesAsync(closedNPSIds);
        }
    }

    /**
     * Initiates asynchronous AI summary generation for closed NPS surveys
     * Queries NPS responses and enqueues Queueable job for processing
     * @param npsIds Set of NPS Ids that were just closed
     */
    @TestVisible
    private static void generateAISummariesAsync(Set<Id> npsIds) {
        try {
            // Query all NPS responses for these NPS records in bulk
            List<NPS_Response__c> responses = queryNPSResponses(npsIds);

            // Group responses by NPS Id for efficient processing
            Map<Id, List<NPS_Response__c>> npsResponsesMap = groupResponsesByNPS(responses);

            // Log summary information
            System.debug('AF_NPSTriggerHandler: Processing ' + npsIds.size() + ' NPS surveys');
            System.debug('AF_NPSTriggerHandler: Retrieved ' + responses.size() + ' total responses');

            // Enqueue job for async processing (skip in test context unless needed)
            if (!Test.isRunningTest()) {
                System.enqueueJob(new AF_NPSAISummaryQueueable(npsResponsesMap, npsIds));
                System.debug('AF_NPSTriggerHandler: Enqueued AF_NPSAISummaryQueueable job');
            } else {
                // In test context, provide visibility
                System.debug('AF_NPSTriggerHandler: Test context - would enqueue AF_NPSAISummaryQueueable');
            }

        } catch (Exception e) {
            // Log error but don't fail the trigger
            System.debug(LoggingLevel.ERROR,
                'AF_NPSTriggerHandler: Error in generateAISummariesAsync: ' + e.getMessage() +
                '\nStack Trace: ' + e.getStackTraceString());
        }
    }

    /**
     * Queries all NPS Response records for given NPS Ids
     * Retrieves all fields needed for AI summary generation
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

    /**
     * Utility method to check if a record should trigger AI summary generation
     * Validates business rules beyond just status change
     * @param nps The NPS record
     * @return true if summary should be generated, false otherwise
     */
    @TestVisible
    private static Boolean shouldGenerateSummary(NPS__c nps) {
        // Must be Closed status
        if (nps.Status__c != 'Closed') {
            return false;
        }

        // Must have Account relationship (business rule)
        if (nps.Account__c == null) {
            System.debug(LoggingLevel.WARN,
                'AF_NPSTriggerHandler: Skipping NPS ' + nps.Id + ' - No Account');
            return false;
        }

        // Additional business rules can be added here
        // For example: minimum score threshold, record type checks, etc.

        return true;
    }
}
