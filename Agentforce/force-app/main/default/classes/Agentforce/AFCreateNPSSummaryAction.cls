/**
 * @Name         AFCreateNPSSummaryAction
 * @Author       Agentforce Implementation Team
 * @Date         2025-01-15
 * @Description  Invocable Apex class to create NPS survey summaries synchronously by survey name.
 *               Used by GenAI functions to create summaries and return summary data for display.
 */
public with sharing class AFCreateNPSSummaryAction {

    /**
     * Input wrapper for invocable method
     */
    public class SummaryRequest {
        @InvocableVariable(label='Survey Name' required=true)
        public String surveyName;
    }

    /**
     * Response wrapper for invocable method - contains single summary
     */
    public class SummaryResponse {
        @AuraEnabled @InvocableVariable
        public NPSSummaryItem summary;
    }

    /**
     * Individual summary item wrapper - matches NPSSurveySummaryWrapper structure
     */
    public class NPSSummaryItem {
        @AuraEnabled
        public String id;
        
        @AuraEnabled
        public String name;
        
        @AuraEnabled
        public Decimal npsScore;
        
        @AuraEnabled
        public Date surveyDate;
        
        @AuraEnabled
        public String sentimentAnalysis;
        
        @AuraEnabled
        public Boolean followUpRequired;
        
        @AuraEnabled
        public DateTime summaryGenerationDate;
        
        @AuraEnabled
        public String accountName;
        
        @AuraEnabled
        public String npsSurveyName;
    }

    /**
     * Creates an AI summary for the given NPS survey by name (synchronously)
     * @param requests List of SummaryRequest objects containing survey name
     * @return List of SummaryResponse containing summary data
     */
    @InvocableMethod(label='Create NPS Summary' description='Creates an AI-generated summary for an NPS survey by name. Returns summary record data.')
    public static List<SummaryResponse> createSummary(List<SummaryRequest> requests) {
        List<SummaryResponse> results = new List<SummaryResponse>();
        
        if (requests == null || requests.isEmpty()) {
            SummaryResponse errorResponse = new SummaryResponse();
            errorResponse.summary = null;
            results.add(errorResponse);
            return results;
        }
        
        SummaryRequest request = requests[0];
        String surveyName = request != null ? request.surveyName : null;
        
        if (String.isBlank(surveyName)) {
            SummaryResponse errorResponse = new SummaryResponse();
            errorResponse.summary = null;
            results.add(errorResponse);
            return results;
        }
        
        try {
            // Lookup NPS survey by name (case-insensitive, partial match)
            List<NPS__c> npsRecords = [
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
                WHERE Name = :surveyName
                LIMIT 1
            ];
            
            if (npsRecords.isEmpty()) {
                // Try case-insensitive search
                npsRecords = [
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
                    WHERE Name LIKE :('%' + surveyName + '%')
                    LIMIT 1
                ];
            }
            
            if (npsRecords.isEmpty()) {
                SummaryResponse errorResponse = new SummaryResponse();
                errorResponse.summary = null;
                results.add(errorResponse);
                return results;
            }
            
            NPS__c nps = npsRecords[0];
            
            // Validate status
            if (nps.Status__c != 'Closed') {
                SummaryResponse errorResponse = new SummaryResponse();
                errorResponse.summary = null;
                results.add(errorResponse);
                return results;
            }

            // Check for existing summaries (for informational purposes only)
            List<NPS_Survey_Summary__c> existingSummaries = [
                SELECT Id
                FROM NPS_Survey_Summary__c
                WHERE NPS_Survey__c = :nps.Id
            ];

            System.debug('AFCreateNPSSummaryAction: Found ' + existingSummaries.size() + ' existing summary(ies). Creating new summary without deleting previous ones.');

            // Query NPS responses
            List<NPS_Response__c> responsesList = [
                SELECT Id, NPS__c, Name,
                       Question__c, Question_Text__c, Question_ID__c,
                       Score__c, Answer__c,
                       Suggestion_for_improvement__c,
                       Order__c, Overall_Comments__c
                FROM NPS_Response__c
                WHERE NPS__c = :nps.Id
                ORDER BY Order__c NULLS LAST
            ];
            
            // Validate required data
            if (!AF_NPSPromptBuilder.hasRequiredData(nps, responsesList)) {
                SummaryResponse errorResponse = new SummaryResponse();
                errorResponse.summary = null;
                results.add(errorResponse);
                return results;
            }
            
            // Create summary synchronously
            NPS_Survey_Summary__c summaryRecord = createSummarySynchronously(nps, responsesList);
            
            if (summaryRecord == null || summaryRecord.Id == null) {
                SummaryResponse errorResponse = new SummaryResponse();
                errorResponse.summary = null;
                results.add(errorResponse);
                return results;
            }
            
            // Query the created summary with all fields needed for display
            List<NPS_Survey_Summary__c> createdSummaries = [
                SELECT Id, Name, NPS_Score__c, Survey_Date__c, Sentiment_Analysis__c,
                       Follow_Up_Required__c, Summary_Generation_Date__c, Account__r.Name,
                       NPS_Survey__r.Name
                FROM NPS_Survey_Summary__c
                WHERE Id = :summaryRecord.Id
                LIMIT 1
            ];
            
            if (createdSummaries.isEmpty()) {
                SummaryResponse errorResponse = new SummaryResponse();
                errorResponse.summary = null;
                results.add(errorResponse);
                return results;
            }
            
            NPS_Survey_Summary__c createdSummary = createdSummaries[0];
            
            // Build response
            NPSSummaryItem summaryItem = new NPSSummaryItem();
            summaryItem.id = createdSummary.Id;
            summaryItem.name = createdSummary.Name;
            summaryItem.npsScore = createdSummary.NPS_Score__c;
            summaryItem.surveyDate = createdSummary.Survey_Date__c;
            summaryItem.sentimentAnalysis = createdSummary.Sentiment_Analysis__c;
            summaryItem.followUpRequired = createdSummary.Follow_Up_Required__c == true;
            summaryItem.summaryGenerationDate = createdSummary.Summary_Generation_Date__c;
            summaryItem.accountName = createdSummary.Account__r != null ? createdSummary.Account__r.Name : '';
            summaryItem.npsSurveyName = createdSummary.NPS_Survey__r != null ? createdSummary.NPS_Survey__r.Name : '';
            
            SummaryResponse response = new SummaryResponse();
            response.summary = summaryItem;
            results.add(response);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error creating NPS summary: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            SummaryResponse errorResponse = new SummaryResponse();
            errorResponse.summary = null;
            results.add(errorResponse);
        }
        
        return results;
    }
    
    /**
     * Creates summary record synchronously by executing the queueable logic inline
     * @param nps The NPS survey record
     * @param responses List of NPS responses
     * @return Created NPS_Survey_Summary__c record
     */
    private static NPS_Survey_Summary__c createSummarySynchronously(NPS__c nps, List<NPS_Response__c> responses) {
        try {
            // Build prompt data
            String promptData = AF_NPSPromptBuilder.buildPromptData(nps, responses);
            
            // Generate AI summary (reuse logic from queueable)
            String aiSummary = generateAISummary(promptData, nps, responses);
            
            // Create summary record
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
            
            // AI-generated content
            summary.AI_Summary__c = aiSummary;
            summary.Summary_Language__c = 'English';
            summary.Created_By_Agentforce__c = true;
            summary.Summary_Generation_Date__c = System.now();
            
            // Parse AI summary to populate specific fields
            parseSummaryFields(summary, aiSummary, nps);
            
            // Insert the summary
            insert summary;
            
            return summary;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in createSummarySynchronously: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            return null;
        }
    }
    
    /**
     * Generates AI summary using Agentforce/Einstein LLM (reused from queueable)
     * @param promptData The formatted prompt string
     * @param nps The NPS survey record
     * @param responses List of responses
     * @return AI-generated summary text
     */
    private static String generateAISummary(String promptData, NPS__c nps, List<NPS_Response__c> responses) {
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
    private static String buildPlaceholderSummary(NPS__c nps, List<NPS_Response__c> responses) {
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
     * Parses AI summary to extract structured data into specific fields
     * @param summary The summary record to populate
     * @param aiSummary The full AI summary text
     * @param nps The NPS survey record
     */
    private static void parseSummaryFields(NPS_Survey_Summary__c summary, String aiSummary, NPS__c nps) {
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
        
        // Placeholder for structured fields
        summary.Key_Insights__c = 'AI insights will be populated here once Agentforce is integrated.';
        summary.Action_Recommendations__c = 'AI recommendations will be populated here once Agentforce is integrated.';
    }
}

