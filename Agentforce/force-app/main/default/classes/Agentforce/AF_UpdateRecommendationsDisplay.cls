/**
 * Utility class to update Action_Recommendations_Display__c field
 * for existing NPS Survey Summary records
 */
public with sharing class AF_UpdateRecommendationsDisplay {
    
    /**
     * Updates the Action_Recommendations_Display__c field for a specific summary record
     * @param summaryId The Id of the NPS_Survey_Summary__c record to update
     */
    public static void updateDisplayField(Id summaryId) {
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

            // Check if we have recommendations JSON
            if (String.isBlank(summary.Action_Recommendations__c)) {
                System.debug('No recommendations found for summary: ' + summaryId);
                return;
            }

            String jsonText = summary.Action_Recommendations__c.trim();
            
            // Defensive parsing: Check if the field contains the full AI summary instead of just JSON
            if (!jsonText.startsWith('[') && !jsonText.startsWith('{')) {
                String extractedJson = AFCreateNPSSummaryAction.extractJsonFromSummary(jsonText);
                if (String.isNotBlank(extractedJson) && extractedJson != '[]') {
                    jsonText = extractedJson;
                } else {
                    System.debug('Could not extract valid JSON from Action_Recommendations__c');
                    return;
                }
            }

            // Parse the JSON
            List<Object> recommendations = (List<Object>) JSON.deserializeUntyped(jsonText);
            
            // Build the display text using the same method as in AFCreateNPSSummaryAction
            String displayText = buildRecommendationsDisplayText(recommendations);
            
            // Update the record
            summary.Action_Recommendations_Display__c = displayText;
            update summary;
            
            System.debug('Successfully updated Action_Recommendations_Display__c for summary: ' + summaryId);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error updating display field: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error updating display field: ' + e.getMessage());
        }
    }

    /**
     * Builds display text from parsed recommendations
     * @param recommendations List of parsed recommendation objects
     * @return Formatted display text
     */
    private static String buildRecommendationsDisplayText(List<Object> recommendations) {
        String displayText = '';
        Integer counter = 1;

        for (Object recObj : recommendations) {
            Map<String, Object> rec = (Map<String, Object>) recObj;
            String recText = (String) rec.get('recommendation');
            if (String.isNotBlank(recText)) {
                displayText += counter + '. ' + recText + '\n';
                
                // Add Type if present
                String type = (String) rec.get('type');
                if (String.isNotBlank(type)) {
                    displayText += '   Type: ' + type + '\n';
                }
                
                // Add Approach if present
                String approach = (String) rec.get('approach');
                if (String.isNotBlank(approach)) {
                    displayText += '   Approach: ' + approach + '\n';
                }
                
                // Add Focus if present
                String focus = (String) rec.get('focus');
                if (String.isNotBlank(focus)) {
                    displayText += '   Focus: ' + focus + '\n';
                }
                
                // Add Sustainability Goal if present and not "Not Applicable"
                String sustainabilityGoal = (String) rec.get('sustainabilityGoal');
                if (String.isNotBlank(sustainabilityGoal) && !sustainabilityGoal.equalsIgnoreCase('Not Applicable')) {
                    displayText += '   Sustainability Goal: ' + sustainabilityGoal + '\n';
                }
                
                // Add Social Value if present and not "Not Applicable"
                String socialValue = (String) rec.get('socialValue');
                if (String.isNotBlank(socialValue) && !socialValue.equalsIgnoreCase('Not Applicable')) {
                    displayText += '   Social Value: ' + socialValue + '\n';
                }
                
                displayText += '\n';
                counter++;
            }
        }

        return displayText.trim();
    }
}

