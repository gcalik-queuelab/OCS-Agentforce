/**
 * @Name         AF_NPSCreateActionsController
 * @Author       Agentforce Implementation Team
 * @Date         2025-01-20
 * @Description  Controller for creating Action records from NPS Survey Summary recommendations
 */
public with sharing class AF_NPSCreateActionsController {

    /**
     * Wrapper class for recommendation data
     */
    public class RecommendationWrapper {
        @AuraEnabled public String recommendation { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public String approach { get; set; }
        @AuraEnabled public String focus { get; set; }
        @AuraEnabled public String sustainabilityGoal { get; set; }
        @AuraEnabled public String socialValue { get; set; }
    }

    /**
     * Wrapper class for response
     */
    public class CreateActionsResponse {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public Integer actionsCreated { get; set; }

        public CreateActionsResponse(Boolean success, String message, Integer actionsCreated) {
            this.success = success;
            this.message = message;
            this.actionsCreated = actionsCreated;
        }
    }

    /**
     * Retrieves and parses recommendations from a Survey Summary record
     * @param summaryId The NPS_Survey_Summary__c record ID
     * @return List of parsed recommendations
     */
    @AuraEnabled(cacheable=true)
    public static List<RecommendationWrapper> getRecommendations(Id summaryId) {
        try {
            // Query the summary record
            List<NPS_Survey_Summary__c> summaries = [
                SELECT Id, Action_Recommendations__c
                FROM NPS_Survey_Summary__c
                WHERE Id = :summaryId
                LIMIT 1
            ];

            if (summaries.isEmpty()) {
                throw new AuraHandledException('Survey Summary not found');
            }

            NPS_Survey_Summary__c summary = summaries[0];

            // Parse JSON recommendations
            if (String.isBlank(summary.Action_Recommendations__c)) {
                return new List<RecommendationWrapper>();
            }

            String jsonText = summary.Action_Recommendations__c.trim();
            
            // Defensive parsing: Check if the field contains the full AI summary instead of just JSON
            // If it doesn't start with '[' or '{', try to extract JSON from it
            if (!jsonText.startsWith('[') && !jsonText.startsWith('{')) {
                // Try to extract JSON from the text (might contain markdown or other text)
                String jsonStart = 'STRUCTURED_RECOMMENDATIONS_START';
                String jsonEnd = 'STRUCTURED_RECOMMENDATIONS_END';
                
                Integer startIndex = jsonText.indexOf(jsonStart);
                Integer endIndex = jsonText.indexOf(jsonEnd);
                
                if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
                    // Extract the JSON array
                    jsonText = jsonText.substring(startIndex + jsonStart.length(), endIndex).trim();
                    
                    // Remove markdown code block markers if present
                    jsonText = jsonText.replaceAll('(?i)^```json\\s*', '');
                    jsonText = jsonText.replaceAll('(?i)^```\\s*', '');
                    jsonText = jsonText.replaceAll('(?i)\\s*```$', '');
                    jsonText = jsonText.trim();
                    
                    // Find the actual JSON array start
                    Integer jsonArrayStart = jsonText.indexOf('[');
                    if (jsonArrayStart != -1) {
                        jsonText = jsonText.substring(jsonArrayStart);
                    }
                    
                    // Find the actual JSON array end
                    Integer jsonArrayEnd = jsonText.lastIndexOf(']');
                    if (jsonArrayEnd != -1) {
                        jsonText = jsonText.substring(0, jsonArrayEnd + 1);
                    }
                    
                    jsonText = jsonText.trim();
                } else {
                    // No structured markers found, return empty list
                    System.debug(LoggingLevel.WARN, 'Action_Recommendations__c does not contain valid JSON structure');
                    return new List<RecommendationWrapper>();
                }
            }

            // Validate JSON format before parsing
            if (String.isBlank(jsonText) || (!jsonText.startsWith('[') && !jsonText.startsWith('{'))) {
                System.debug(LoggingLevel.WARN, 'Action_Recommendations__c does not contain valid JSON');
                return new List<RecommendationWrapper>();
            }

            List<RecommendationWrapper> recommendations = new List<RecommendationWrapper>();
            List<Object> jsonRecs = (List<Object>) JSON.deserializeUntyped(jsonText);

            for (Object recObj : jsonRecs) {
                Map<String, Object> recMap = (Map<String, Object>) recObj;
                RecommendationWrapper wrapper = new RecommendationWrapper();
                wrapper.recommendation = (String) recMap.get('recommendation');
                wrapper.type = (String) recMap.get('type');
                wrapper.approach = (String) recMap.get('approach');
                wrapper.focus = (String) recMap.get('focus');
                wrapper.sustainabilityGoal = (String) recMap.get('sustainabilityGoal');
                wrapper.socialValue = (String) recMap.get('socialValue');
                recommendations.add(wrapper);
            }

            return recommendations;

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error getting recommendations: ' + e.getMessage());
            throw new AuraHandledException('Error retrieving recommendations: ' + e.getMessage());
        }
    }

    /**
     * Creates Action records from selected recommendations
     * @param summaryId The NPS_Survey_Summary__c record ID
     * @param selectedIndices List of indices of selected recommendations (0-based)
     * @return Response wrapper with success status and message
     */
    @AuraEnabled
    public static CreateActionsResponse createActionsFromRecommendations(Id summaryId, List<Integer> selectedIndices) {
        try {
            // Validate inputs
            if (selectedIndices == null || selectedIndices.isEmpty()) {
                return new CreateActionsResponse(false, 'No recommendations selected', 0);
            }

            // Query the summary with related NPS survey data
            List<NPS_Survey_Summary__c> summaries = [
                SELECT Id, Action_Recommendations__c, Account__c, NPS_Survey__c,
                       NPS_Survey__r.OwnerId
                FROM NPS_Survey_Summary__c
                WHERE Id = :summaryId
                LIMIT 1
            ];

            if (summaries.isEmpty()) {
                return new CreateActionsResponse(false, 'Survey Summary not found', 0);
            }

            NPS_Survey_Summary__c summary = summaries[0];

            // Validate related data
            if (summary.NPS_Survey__c == null) {
                return new CreateActionsResponse(false, 'No NPS Survey linked to this Summary', 0);
            }

            // Parse recommendations
            if (String.isBlank(summary.Action_Recommendations__c)) {
                return new CreateActionsResponse(false, 'No recommendations found in Summary', 0);
            }

            String jsonText = summary.Action_Recommendations__c.trim();
            
            // Defensive parsing: Check if the field contains the full AI summary instead of just JSON
            // If it doesn't start with '[' or '{', try to extract JSON from it
            if (!jsonText.startsWith('[') && !jsonText.startsWith('{')) {
                // Try to extract JSON from the text (might contain markdown or other text)
                String jsonStart = 'STRUCTURED_RECOMMENDATIONS_START';
                String jsonEnd = 'STRUCTURED_RECOMMENDATIONS_END';
                
                Integer startIndex = jsonText.indexOf(jsonStart);
                Integer endIndex = jsonText.indexOf(jsonEnd);
                
                if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
                    // Extract the JSON array
                    jsonText = jsonText.substring(startIndex + jsonStart.length(), endIndex).trim();
                    
                    // Remove markdown code block markers if present
                    jsonText = jsonText.replaceAll('(?i)^```json\\s*', '');
                    jsonText = jsonText.replaceAll('(?i)^```\\s*', '');
                    jsonText = jsonText.replaceAll('(?i)\\s*```$', '');
                    jsonText = jsonText.trim();
                    
                    // Find the actual JSON array start
                    Integer jsonArrayStart = jsonText.indexOf('[');
                    if (jsonArrayStart != -1) {
                        jsonText = jsonText.substring(jsonArrayStart);
                    }
                    
                    // Find the actual JSON array end
                    Integer jsonArrayEnd = jsonText.lastIndexOf(']');
                    if (jsonArrayEnd != -1) {
                        jsonText = jsonText.substring(0, jsonArrayEnd + 1);
                    }
                    
                    jsonText = jsonText.trim();
                } else {
                    // No structured markers found
                    return new CreateActionsResponse(false, 'No valid recommendations found in Summary. Please regenerate the summary.', 0);
                }
            }

            // Validate JSON format before parsing
            if (String.isBlank(jsonText) || (!jsonText.startsWith('[') && !jsonText.startsWith('{'))) {
                return new CreateActionsResponse(false, 'Invalid recommendations format. Please regenerate the summary.', 0);
            }

            List<Object> jsonRecs = (List<Object>) JSON.deserializeUntyped(jsonText);
            List<Action__c> actionsToCreate = new List<Action__c>();

            // Get Owner ID from NPS Survey
            Id surveyOwnerId = summary.NPS_Survey__r.OwnerId;
            Date dueDate = System.today().addDays(4);

            // Get Record Type ID for 'Action' record type
            Id actionRecordTypeId = null;
            try {
                RecordType actionRecordType = [
                    SELECT Id 
                    FROM RecordType 
                    WHERE SObjectType = 'Action__c' 
                    AND DeveloperName = 'Action' 
                    LIMIT 1
                ];
                actionRecordTypeId = actionRecordType.Id;
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'Action record type not found: ' + e.getMessage());
            }

            // Create Action records for selected recommendations
            for (Integer index : selectedIndices) {
                if (index >= 0 && index < jsonRecs.size()) {
                    Map<String, Object> recMap = (Map<String, Object>) jsonRecs[index];

                    Action__c action = new Action__c();

                    // Required fields
                    action.Summary__c = (String) recMap.get('recommendation');
                    action.Original_Due_Date__c = dueDate;

                    // Record Type
                    if (actionRecordTypeId != null) {
                        action.RecordTypeId = actionRecordTypeId;
                    }

                    // Owner (Current_Assignee__c is a formula field based on Owner)
                    action.OwnerId = surveyOwnerId;

                    // Dates
                    action.Due_Date__c = dueDate;
                    action.Start_Date__c = System.today();

                    // Status
                    action.Status__c = 'Pending';

                    // AI-generated picklist values
                    action.Type__c = (String) recMap.get('type');
                    action.Approach__c = (String) recMap.get('approach');
                    action.Focus__c = (String) recMap.get('focus');
                    action.Sustainability_Goal__c = (String) recMap.get('sustainabilityGoal');
                    action.Social_Value__c = (String) recMap.get('socialValue');

                    // Relationships
                    action.Account__c = summary.Account__c;
                    action.NPS__c = summary.NPS_Survey__c;

                    actionsToCreate.add(action);
                }
            }

            if (actionsToCreate.isEmpty()) {
                return new CreateActionsResponse(false, 'No valid recommendations to create Actions from', 0);
            }

            // Insert actions
            insert actionsToCreate;

            String successMessage = actionsToCreate.size() + ' Action' +
                                  (actionsToCreate.size() > 1 ? 's' : '') +
                                  ' created successfully';

            return new CreateActionsResponse(true, successMessage, actionsToCreate.size());

        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR, 'DML Error creating actions: ' + e.getMessage());
            return new CreateActionsResponse(false, 'Database error: ' + e.getDmlMessage(0), 0);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error creating actions: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            return new CreateActionsResponse(false, 'Error: ' + e.getMessage(), 0);
        }
    }
}
