/**
 * @Name         AF_NPSAISummaryQueueable
 * @Author       Agentforce Implementation Team
 * @Date         2025-01-15
 * @Description  Queueable class to asynchronously generate AI summaries for closed NPS surveys
 *               using Agentforce/Einstein LLM. Creates NPS_Survey_Summary__c records with
 *               AI-generated insights and recommendations.
 */
public class AF_NPSAISummaryQueueable implements Queueable, Database.AllowsCallouts {

    private Map<Id, List<NPS_Response__c>> npsResponsesMap;
    private Set<Id> npsIds;

    /**
     * Constructor
     * @param responseMap Map of NPS Id to list of responses
     * @param ids Set of NPS Ids to process
     */
    public AF_NPSAISummaryQueueable(Map<Id, List<NPS_Response__c>> responseMap, Set<Id> ids) {
        this.npsResponsesMap = responseMap;
        this.npsIds = ids;
    }

    /**
     * Execute method - processes NPS surveys and generates AI summaries
     * @param context Queueable context
     */
    public void execute(QueueableContext context) {
        try {
            // Query full NPS records with related data
            Map<Id, NPS__c> npsMap = queryNPSRecords();

            // Query previous summaries for trend analysis
            Map<Id, List<NPS_Survey_Summary__c>> npsToPreviousSummariesMap = queryPreviousSummaries();

            // List to hold new NPS Summary records
            List<NPS_Survey_Summary__c> summariesToInsert = new List<NPS_Survey_Summary__c>();

            // Process each NPS survey
            for (Id npsId : npsIds) {
                try {
                    NPS__c nps = npsMap.get(npsId);
                    List<NPS_Response__c> responses = npsResponsesMap.get(npsId);

                    // Validate we have required data
                    if (!AF_NPSPromptBuilder.hasRequiredData(nps, responses)) {
                        System.debug(LoggingLevel.WARN,
                            'Skipping NPS ' + npsId + ': Missing required data');
                        continue;
                    }

                    // Get previous summaries for this specific NPS Survey
                    List<NPS_Survey_Summary__c> previousSummaries = new List<NPS_Survey_Summary__c>();
                    if (npsToPreviousSummariesMap.containsKey(npsId)) {
                        previousSummaries = npsToPreviousSummariesMap.get(npsId);
                    }

                    // Build prompt data with historical trend data
                    String promptData = AF_NPSPromptBuilder.buildPromptData(nps, responses, previousSummaries);

                    // Call Agentforce to generate summary
                    String aiSummary = generateAISummary(promptData, nps, responses);

                    // Parse AI response and create summary record
                    NPS_Survey_Summary__c summary = createSummaryRecord(nps, aiSummary);
                    summariesToInsert.add(summary);

                } catch (Exception e) {
                    // Log error but continue processing other records
                    System.debug(LoggingLevel.ERROR,
                        'Error processing NPS ' + npsId + ': ' + e.getMessage() +
                        '\nStack Trace: ' + e.getStackTraceString());
                }
            }

            // Insert summary records with partial success
            if (!summariesToInsert.isEmpty()) {
                insertSummaries(summariesToInsert);
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                'Fatal error in AF_NPSAISummaryQueueable: ' + e.getMessage() +
                '\nStack Trace: ' + e.getStackTraceString());
        }
    }

    /**
     * Queries previous NPS Survey Summaries for trend analysis
     * @return Map of NPS Survey Id to list of previous summaries (ordered by Created Date DESC)
     */
    private Map<Id, List<NPS_Survey_Summary__c>> queryPreviousSummaries() {
        if (npsIds == null || npsIds.isEmpty()) {
            return new Map<Id, List<NPS_Survey_Summary__c>>();
        }

        // Query all previous summaries for these NPS Surveys
        List<NPS_Survey_Summary__c> allPreviousSummaries = [
            SELECT Id, Name, Survey_Date__c,
                   NPS_Score__c, Total_Score__c,
                   Number_of_Scored_Responses__c,
                   Sentiment_Analysis__c,
                   Summary_Generation_Date__c,
                   NPS_Survey__c,
                   CreatedDate
            FROM NPS_Survey_Summary__c
            WHERE NPS_Survey__c IN :npsIds
            ORDER BY NPS_Survey__c, CreatedDate DESC
        ];

        // Group by NPS Survey Id
        Map<Id, List<NPS_Survey_Summary__c>> npsToSummariesMap = new Map<Id, List<NPS_Survey_Summary__c>>();
        for (NPS_Survey_Summary__c summary : allPreviousSummaries) {
            if (!npsToSummariesMap.containsKey(summary.NPS_Survey__c)) {
                npsToSummariesMap.put(summary.NPS_Survey__c, new List<NPS_Survey_Summary__c>());
            }
            npsToSummariesMap.get(summary.NPS_Survey__c).add(summary);
        }

        return npsToSummariesMap;
    }

    /**
     * Query NPS records with all related data needed for summary
     * @return Map of NPS Id to NPS record
     */
    private Map<Id, NPS__c> queryNPSRecords() {
        return new Map<Id, NPS__c>([
            SELECT Id, Name, Status__c, Survey_Category__c,
                   Account__c, Account__r.Name,
                   NPS_Contact__c, NPS_Contact__r.Name,
                   NPS_Surveyor__c, NPS_Surveyor__r.Name,
                   Visiting_Contact__c, Visiting_Contact__r.Name,
                   Visit_Start__c, Visit_Finish__c,
                   Average_Score__c, Recommend_Us_Score__c,
                   Total_NPS_Score__c, Number_of_NPS_Responses__c,
                   Number_of_Scored_NPS_Responses__c,
                   Comments__c, Visiting_Comments__c,
                   Due_Date__c, Reviewed__c
            FROM NPS__c
            WHERE Id IN :npsIds
        ]);
    }

    /**
     * Generates AI summary using Agentforce/Einstein LLM
     * @param promptData The formatted prompt string
     * @param nps The NPS survey record
     * @param responses List of responses
     * @return AI-generated summary text
     */
    private String generateAISummary(String promptData, NPS__c nps, List<NPS_Response__c> responses) {
        // Log the prompt data being sent
        System.debug('=== PROMPT DATA FOR NPS ' + nps.Name + ' ===');
        System.debug(promptData);
        System.debug('=== END PROMPT DATA ===');

        try {
            // Step 1: Create input value wrapper
            ConnectApi.WrappedValue inputValue = new ConnectApi.WrappedValue();
            inputValue.value = promptData;

            // Step 2: Create input parameters map
            Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
            inputParams.put('Input:NPS_Data', inputValue);

            // Step 3: Configure the invocation request
            ConnectApi.EinsteinPromptTemplateGenerationsInput promptInput =
                new ConnectApi.EinsteinPromptTemplateGenerationsInput();

            // Additional configuration
            promptInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            promptInput.additionalConfig.applicationName = 'PromptBuilderPreview';
            promptInput.additionalConfig.numGenerations = 1;
            promptInput.additionalConfig.enablePiiMasking = false;

            // Set request properties
            promptInput.isPreview = false;
            promptInput.inputParams = inputParams;

            // Step 4: Call the Agentforce API
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                    'NPS_Survey_Summary_Generator',
                    promptInput
                );

            // Step 5: Handle the response
            if (output != null &&
                output.generations != null &&
                output.generations.size() > 0) {

                ConnectApi.EinsteinLLMGenerationItemOutput generationResult = output.generations[0];
                String aiGeneratedText = generationResult.text;

                System.debug('=== AI GENERATED SUMMARY ===');
                System.debug(aiGeneratedText);
                System.debug('=== END AI SUMMARY ===');

                return aiGeneratedText;

            } else if (output != null &&
                       output.generationErrors != null &&
                       output.generationErrors.size() > 0) {

                // Handle errors from AI generation
                String errorMessages = '';
                for (ConnectApi.EinsteinPromptTemplateGenerationsError error : output.generationErrors) {
                    errorMessages += error.errorMessage + ' (Code: ' + error.messageCode + ') ';
                }

                System.debug(LoggingLevel.ERROR, 'Agentforce generation errors: ' + errorMessages);
                throw new CalloutException('AI generation failed: ' + errorMessages);
            } else {
                throw new CalloutException('No AI response received');
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Agentforce call failed: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());

            // Fall back to placeholder summary if AI call fails
            System.debug(LoggingLevel.WARN, 'Falling back to placeholder summary due to error');
            return buildPlaceholderSummary(nps, responses);
        }
    }

    /**
     * Builds a placeholder summary for testing before Agentforce integration
     * @param nps The NPS survey record
     * @param responses List of responses
     * @return Placeholder summary text
     */
    private String buildPlaceholderSummary(NPS__c nps, List<NPS_Response__c> responses) {
        String summary = '';

        summary += 'EXECUTIVE SUMMARY\n';
        summary += 'This is a placeholder summary for NPS Survey ' + nps.Name;
        summary += ' pending Agentforce integration. ';
        summary += 'The survey received ' + responses.size() + ' responses ';
        summary += 'with an average NPS score of ' + nps.Recommend_Us_Score__c + '/10. ';
        summary += 'Category: ' + nps.Survey_Category__c + '.\n\n';

        summary += 'KEY STRENGTHS\n';
        summary += '- Survey data collected successfully\n';
        summary += '- Responses processed and ready for AI analysis\n\n';

        summary += 'AREAS FOR IMPROVEMENT\n';
        summary += '- Agentforce integration pending\n';
        summary += '- AI-generated insights to be implemented\n\n';

        summary += 'RECOMMENDED ACTIONS\n';
        summary += '1. Complete Agentforce prompt template configuration\n';
        summary += '2. Enable Einstein AI in the org\n';
        summary += '3. Test with real AI generation\n\n';

        summary += 'NOTE: This is a system-generated placeholder. ';
        summary += 'Once Agentforce is configured, this will be replaced with AI-generated insights.\n';

        return summary;
    }

    /**
     * Creates NPS_Survey_Summary__c record from AI summary
     * @param nps The NPS survey record
     * @param aiSummary The AI-generated summary text
     * @return NPS_Survey_Summary__c record ready to insert
     */
    private NPS_Survey_Summary__c createSummaryRecord(NPS__c nps, String aiSummary) {
        NPS_Survey_Summary__c summary = new NPS_Survey_Summary__c();

        // Relationships
        summary.NPS_Survey__c = nps.Id;
        summary.Account__c = nps.Account__c;
        summary.NPS_Contact__c = nps.NPS_Contact__c;
        summary.NPS_Surveyor__c = nps.NPS_Surveyor__c;

        // Survey metadata
        summary.Survey_Date__c = nps.Visit_Start__c != null ? nps.Visit_Start__c.date() : null;
        summary.Survey_Status__c = nps.Status__c;
        summary.Reviewed_Date__c = nps.Reviewed__c;

        // Scores
        summary.NPS_Score__c = nps.Recommend_Us_Score__c;
        summary.Total_Score__c = nps.Total_NPS_Score__c;
        summary.Average_Score__c = nps.Average_Score__c;
        summary.Number_of_Responses__c = nps.Number_of_NPS_Responses__c;
        summary.Number_of_Scored_Responses__c = nps.Number_of_Scored_NPS_Responses__c;

        // AI-generated content (remove structured recommendations JSON)
        summary.AI_Summary__c = removeStructuredRecommendationsFromSummary(aiSummary);
        summary.Summary_Language__c = 'English';
        summary.Created_By_Agentforce__c = true;
        summary.Summary_Generation_Date__c = System.now();

        // Parse AI summary to populate specific fields
        // TODO: Implement actual parsing when Agentforce returns structured data
        parseSummaryFields(summary, aiSummary, nps);

        return summary;
    }

    /**
     * Parses AI summary to extract structured data into specific fields
     * @param summary The summary record to populate
     * @param aiSummary The full AI summary text
     * @param nps The NPS survey record
     */
    private void parseSummaryFields(NPS_Survey_Summary__c summary, String aiSummary, NPS__c nps) {
        // Set sentiment based on survey category
        if (nps.Survey_Category__c == 'Promoter') {
            summary.Sentiment_Analysis__c = 'Positive';
            summary.Follow_Up_Required__c = false;
        } else if (nps.Survey_Category__c == 'Detractor') {
            summary.Sentiment_Analysis__c = 'Negative';
            summary.Follow_Up_Required__c = true;
        } else if (nps.Survey_Category__c == 'Passive') {
            summary.Sentiment_Analysis__c = 'Neutral';
            summary.Follow_Up_Required__c = true;
        } else {
            summary.Sentiment_Analysis__c = 'Mixed';
            summary.Follow_Up_Required__c = false;
        }

        // Parse structured recommendations from AI summary
        parseRecommendations(summary, aiSummary);

        // Placeholder for other structured fields
        summary.Key_Insights__c = 'AI insights will be populated here once Agentforce is integrated.';
    }

    /**
     * Extracts and cleans JSON text from AI summary response
     * @param aiSummary The full AI summary text
     * @return Cleaned JSON string, or null if not found
     */
    private String extractJsonFromSummary(String aiSummary) {
        String jsonStart = 'STRUCTURED_RECOMMENDATIONS_START';
        String jsonEnd = 'STRUCTURED_RECOMMENDATIONS_END';

        Integer startIndex = aiSummary.indexOf(jsonStart);
        Integer endIndex = aiSummary.indexOf(jsonEnd);

        if (startIndex == -1 || endIndex == -1 || endIndex <= startIndex) {
            return null;
        }

        // Extract the JSON array - start after the marker
        String jsonText = aiSummary.substring(startIndex + jsonStart.length(), endIndex).trim();
        
        // Remove markdown code block markers if present (```json, ```, etc.)
        jsonText = jsonText.replaceAll('(?i)^```json\\s*', '');
        jsonText = jsonText.replaceAll('(?i)^```\\s*', '');
        jsonText = jsonText.replaceAll('(?i)\\s*```$', '');
        jsonText = jsonText.trim();
        
        // Find the actual JSON array start (should start with '[')
        Integer jsonArrayStart = jsonText.indexOf('[');
        if (jsonArrayStart != -1) {
            jsonText = jsonText.substring(jsonArrayStart);
        }
        
        // Find the actual JSON array end (should end with ']')
        Integer jsonArrayEnd = jsonText.lastIndexOf(']');
        if (jsonArrayEnd != -1) {
            jsonText = jsonText.substring(0, jsonArrayEnd + 1);
        }
        
        jsonText = jsonText.trim();
        
        // Validate that we have valid JSON
        if (String.isNotBlank(jsonText) && jsonText.startsWith('[') && jsonText.endsWith(']')) {
            return jsonText;
        }
        
        return null;
    }

    /**
     * Parses recommendations from AI summary and populates both JSON and display fields
     * @param summary The summary record to populate
     * @param aiSummary The full AI summary text
     */
    private void parseRecommendations(NPS_Survey_Summary__c summary, String aiSummary) {
        try {
            String jsonText = extractJsonFromSummary(aiSummary);

            if (String.isNotBlank(jsonText)) {
                // Test parse to ensure it's valid JSON
                List<Object> testParse = (List<Object>) JSON.deserializeUntyped(jsonText);
                
                // Store JSON in Action_Recommendations__c
                summary.Action_Recommendations__c = jsonText;

                // Parse JSON to create display text
                String displayText = buildRecommendationsDisplayText(testParse);
                summary.Action_Recommendations_Display__c = displayText;

                System.debug('Successfully parsed ' + testParse.size() + ' recommendations');
            } else {
                // Fallback if structured data not found
                System.debug(LoggingLevel.WARN, 'Structured recommendations not found in AI response');
                summary.Action_Recommendations__c = '[]';
                summary.Action_Recommendations_Display__c = 'No structured recommendations generated. Please regenerate the summary.';
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error parsing recommendations: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            summary.Action_Recommendations__c = '[]';
            summary.Action_Recommendations_Display__c = 'Error parsing recommendations. Please regenerate the summary.';
        }
    }

    /**
     * Builds display text from parsed recommendations
     * @param recommendations List of parsed recommendation objects
     * @return Formatted display text
     */
    private String buildRecommendationsDisplayText(List<Object> recommendations) {
        String displayText = '';
        Integer counter = 1;

        for (Object recObj : recommendations) {
            Map<String, Object> rec = (Map<String, Object>) recObj;
            String recText = (String) rec.get('recommendation');
            if (String.isNotBlank(recText)) {
                displayText += counter + '. ' + recText + '\n';
                
                // Always add Type (default to "Not Applicable" if not present)
                String type = (String) rec.get('type');
                displayText += '   Type: ' + (String.isNotBlank(type) ? type : 'Not Applicable') + '\n';
                
                // Always add Approach (default to "Not Applicable" if not present)
                String approach = (String) rec.get('approach');
                displayText += '   Approach: ' + (String.isNotBlank(approach) ? approach : 'Not Applicable') + '\n';
                
                // Always add Focus (default to "Not Applicable" if not present)
                String focus = (String) rec.get('focus');
                displayText += '   Focus: ' + (String.isNotBlank(focus) ? focus : 'Not Applicable') + '\n';
                
                // Always add Sustainability Goal (default to "Not Applicable" if not present)
                String sustainabilityGoal = (String) rec.get('sustainabilityGoal');
                displayText += '   Sustainability Goal: ' + (String.isNotBlank(sustainabilityGoal) ? sustainabilityGoal : 'Not Applicable') + '\n';
                
                // Always add Social Value (default to "Not Applicable" if not present)
                String socialValue = (String) rec.get('socialValue');
                displayText += '   Social Value: ' + (String.isNotBlank(socialValue) ? socialValue : 'Not Applicable') + '\n';
                
                displayText += '\n';
                counter++;
            }
        }

        return displayText.trim();
    }

    /**
     * Inserts summary records with partial success handling
     * @param summaries List of summary records to insert
     */
    private void insertSummaries(List<NPS_Survey_Summary__c> summaries) {
        Database.SaveResult[] results = Database.insert(summaries, false);

        // Log any failures
        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                System.debug(LoggingLevel.ERROR,
                    'Failed to insert summary for NPS ' + summaries[i].NPS_Survey__c);
                for (Database.Error err : results[i].getErrors()) {
                    System.debug(LoggingLevel.ERROR,
                        'Error: ' + err.getMessage() + ' (Fields: ' + err.getFields() + ')');
                }
            } else {
                System.debug('Successfully created summary: ' + results[i].getId());
            }
        }
    }

    /**
     * Removes the structured recommendations JSON section from the AI summary
     * This keeps the AI_Summary__c field clean without the JSON recommendations
     * @param aiSummary The full AI summary text
     * @return AI summary without the structured recommendations section
     */
    private String removeStructuredRecommendationsFromSummary(String aiSummary) {
        if (String.isBlank(aiSummary)) {
            return aiSummary;
        }

        String jsonStart = 'STRUCTURED_RECOMMENDATIONS_START';
        String jsonEnd = 'STRUCTURED_RECOMMENDATIONS_END';

        Integer startIndex = aiSummary.indexOf(jsonStart);
        Integer endIndex = aiSummary.indexOf(jsonEnd);

        if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
            // Look for markdown code block markers before STRUCTURED_RECOMMENDATIONS_START
            String beforeSection = aiSummary.substring(0, startIndex);
            Integer codeBlockStart = beforeSection.lastIndexOf('```');
            if (codeBlockStart != -1) {
                // Check if it's ```json or just ```
                String codeBlockMarker = beforeSection.substring(codeBlockStart);
                if (codeBlockMarker.startsWith('```json') || codeBlockMarker.startsWith('```')) {
                    // Find the start of the line containing the code block marker
                    Integer lineStart = beforeSection.lastIndexOf('\n', codeBlockStart);
                    if (lineStart == -1) {
                        lineStart = 0;
                    } else {
                        lineStart++; // Include the newline
                    }
                    startIndex = lineStart;
                }
            }
            
            // Look for markdown code block markers after STRUCTURED_RECOMMENDATIONS_END
            String afterSection = aiSummary.substring(endIndex + jsonEnd.length());
            Integer codeBlockEnd = afterSection.indexOf('```');
            if (codeBlockEnd != -1) {
                // Find the end of the line containing the closing code block marker
                Integer lineEnd = afterSection.indexOf('\n', codeBlockEnd);
                if (lineEnd != -1) {
                    endIndex = endIndex + jsonEnd.length() + lineEnd + 1; // Include the newline
                } else {
                    endIndex = endIndex + jsonEnd.length() + codeBlockEnd + 3; // Include ``` (3 chars)
                }
            } else {
                endIndex = endIndex + jsonEnd.length();
            }
            
            // Remove everything from the start (including code block markers) to the end
            String before = aiSummary.substring(0, startIndex);
            String after = aiSummary.substring(endIndex);
            
            // Clean up any extra whitespace/newlines
            String cleaned = (before + after).trim();
            
            // Remove any double newlines that might have been created
            cleaned = cleaned.replaceAll('\n{3,}', '\n\n');
            
            // Remove any remaining standalone ```json or ``` markers
            cleaned = cleaned.replaceAll('(?i)\\s*```json\\s*', '');
            cleaned = cleaned.replaceAll('\\s*```\\s*', '');
            
            return cleaned.trim();
        }

        return aiSummary;
    }
}
