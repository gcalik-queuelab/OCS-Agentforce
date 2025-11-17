/**
 * @description Queueable class for asynchronous Account Summary AI generation
 * @author Agentforce POC
 * @date 2025
 */
public class AF_AccountSummaryQueueable implements Queueable, Database.AllowsCallouts {

    private Map<Id, AF_AccountSummaryPromptBuilder.AccountSummaryData> accountDataMap;
    private static final String DEFAULT_MODEL = 'sfdc_ai__DefaultGPT5';

    /**
     * @description Constructor
     * @param dataMap Map of Account ID to AccountSummaryData
     */
    public AF_AccountSummaryQueueable(Map<Id, AF_AccountSummaryPromptBuilder.AccountSummaryData> dataMap) {
        this.accountDataMap = dataMap;
    }

    /**
     * @description Execute method for Queueable interface
     * @param context QueueableContext
     */
    public void execute(QueueableContext context) {
        List<Account_Summary__c> summariesToInsert = new List<Account_Summary__c>();

        for (Id accountId : accountDataMap.keySet()) {
            try {
                AF_AccountSummaryPromptBuilder.AccountSummaryData data = accountDataMap.get(accountId);

                // Build prompt
                String promptData = AF_AccountSummaryPromptBuilder.buildPromptData(data);

                // Determine prompt template name based on trigger type
                String templateName = getTemplateNameForTriggerType(data.triggerType);

                // Track processing time
                Long startTime = System.currentTimeMillis();

                // Call AI
                String aiSummary = generateAISummary(promptData, templateName);

                Long processingTime = System.currentTimeMillis() - startTime;

                // Create summary record
                Account_Summary__c summary = createSummaryRecord(data, aiSummary, processingTime, templateName);
                summariesToInsert.add(summary);

            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR,
                    'Error generating summary for Account ' + accountId + ': ' + e.getMessage());
                System.debug(LoggingLevel.ERROR, 'Stack Trace: ' + e.getStackTraceString());

                // Create failed summary record
                Account_Summary__c failedSummary = createFailedSummaryRecord(
                    accountDataMap.get(accountId),
                    e.getMessage()
                );
                summariesToInsert.add(failedSummary);
            }
        }

        // Insert all summaries (partial success allowed)
        if (!summariesToInsert.isEmpty()) {
            Database.SaveResult[] results = Database.insert(summariesToInsert, false);

            // Log any failures
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    System.debug(LoggingLevel.ERROR,
                        'Failed to insert summary: ' + results[i].getErrors());
                }
            }
        }
    }

    /**
     * @description Calls Agentforce AI to generate summary
     * @param promptData The formatted prompt data
     * @param templateName The prompt template to use
     * @return String AI-generated summary
     */
    private String generateAISummary(String promptData, String templateName) {
        System.debug('=== PROMPT DATA FOR TEMPLATE ' + templateName + ' ===');
        System.debug('Prompt data length: ' + (promptData != null ? promptData.length() : 0));
        System.debug('=== END PROMPT DATA ===');

        try {
            // Create input wrapper
            ConnectApi.WrappedValue inputValue = new ConnectApi.WrappedValue();
            inputValue.value = promptData;

            // Create input parameters map
            Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
            inputParams.put('Input:Account_Data', inputValue);

            // Configure request
            ConnectApi.EinsteinPromptTemplateGenerationsInput promptInput =
                new ConnectApi.EinsteinPromptTemplateGenerationsInput();
            promptInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
            promptInput.additionalConfig.applicationName = 'PromptBuilderPreview';
            promptInput.additionalConfig.numGenerations = 1;
            promptInput.additionalConfig.enablePiiMasking = false;
            promptInput.isPreview = false;
            promptInput.inputParams = inputParams;

            // Call Agentforce
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output =
                ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                    templateName,
                    promptInput
                );

            // Handle the response
            if (output != null &&
                output.generations != null &&
                output.generations.size() > 0) {

                ConnectApi.EinsteinLLMGenerationItemOutput generationResult = output.generations[0];
                String aiGeneratedText = generationResult.text;

                System.debug('=== AI GENERATED SUMMARY ===');
                System.debug('Summary length: ' + (aiGeneratedText != null ? aiGeneratedText.length() : 0));
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
                throw new CalloutException('No AI response received - output was null or empty');
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Agentforce call failed: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            throw e;
        }
    }

    /**
     * @description Creates Account_Summary__c record from AI response
     * @param data AccountSummaryData containing source information
     * @param aiSummary The AI-generated summary text
     * @param processingTime Processing time in milliseconds
     * @param templateName The prompt template used
     * @return Account_Summary__c The populated summary record
     */
    private Account_Summary__c createSummaryRecord(
        AF_AccountSummaryPromptBuilder.AccountSummaryData data,
        String aiSummary,
        Long processingTime,
        String templateName
    ) {
        Account_Summary__c summary = new Account_Summary__c();

        // Core fields
        summary.Account__c = data.account.Id;
        summary.Summary_Type__c = getSummaryType(data.triggerType);
        summary.Trigger_Record_Type__c = data.triggerType;

        // AI content
        summary.AI_Summary__c = aiSummary;
        summary.Executive_Summary__c = extractSection(aiSummary, 'EXECUTIVE SUMMARY');
        summary.Key_Insights__c = extractSection(aiSummary, 'KEY INSIGHTS');
        summary.Opportunities_Identified__c = extractSection(aiSummary, 'OPPORTUNITIES IDENTIFIED');
        summary.Risk_Factors__c = extractSection(aiSummary, 'RISK FACTORS');
        summary.Action_Recommendations__c = extractSection(aiSummary, 'ACTION RECOMMENDATIONS');

        // Source data context
        summary.Account_Type_Current__c = data.account.Type;
        summary.Account_Type_Previous__c = data.previousAccountType;
        summary.Related_Opportunity_Count__c = data.opportunities.size();
        summary.Related_Lead_Count__c = data.leads.size();
        summary.Related_Contract_Count__c = data.contracts.size();
        summary.Related_NPS_Summary_Count__c = data.npsSummaries.size();

        // Calculate data analysis period
        Date periodStart = calculatePeriodStart(data);
        summary.Data_Analysis_Period_Start__c = periodStart;
        summary.Data_Analysis_Period_End__c = Date.today();

        // Metadata
        summary.Summary_Language__c = 'English';
        summary.Summary_Generation_Date__c = DateTime.now();
        summary.Created_By_Agentforce__c = true;
        summary.AI_Model_Version__c = DEFAULT_MODEL;
        summary.Prompt_Template_Used__c = templateName;
        summary.Processing_Time_Seconds__c = processingTime / 1000.0;
        summary.Generation_Status__c = 'Completed';

        // Relationships
        summary.Account_Owner__c = data.account.OwnerId;

        // Store related record IDs as JSON
        summary.Related_Opportunities__c = serializeIds(getOpportunityIds(data.opportunities));
        summary.Related_Leads__c = serializeIds(getLeadIds(data.leads));
        summary.Related_Contracts__c = serializeIds(getContractIds(data.contracts));
        summary.Related_NPS_Surveys__c = serializeIds(getNPSIds(data.npsSummaries));

        return summary;
    }

    /**
     * @description Creates a failed summary record when AI generation fails
     * @param data AccountSummaryData containing source information
     * @param errorMessage The error message
     * @return Account_Summary__c The failed summary record
     */
    private Account_Summary__c createFailedSummaryRecord(
        AF_AccountSummaryPromptBuilder.AccountSummaryData data,
        String errorMessage
    ) {
        Account_Summary__c summary = new Account_Summary__c();

        summary.Account__c = data.account.Id;
        summary.Summary_Type__c = getSummaryType(data.triggerType);
        summary.Trigger_Record_Type__c = data.triggerType;
        summary.Generation_Status__c = 'Failed';
        summary.Summary_Language__c = 'English';
        summary.Summary_Generation_Date__c = DateTime.now();
        summary.Created_By_Agentforce__c = true;
        summary.Account_Owner__c = data.account.OwnerId;

        // Store detailed error in AI Summary field (truncate if too long)
        String fullErrorMessage = 'Summary generation failed: ' + errorMessage;
        if (fullErrorMessage.length() > 131072) {
            fullErrorMessage = fullErrorMessage.substring(0, 131000) + '... (truncated)';
        }
        summary.AI_Summary__c = fullErrorMessage;
        summary.Executive_Summary__c = 'An error occurred during AI summary generation. Error: ' + 
            (errorMessage.length() > 5000 ? errorMessage.substring(0, 5000) : errorMessage);

        return summary;
    }

    /**
     * @description Extracts a specific section from the AI summary
     * @param fullSummary The complete AI summary
     * @param sectionName The section to extract
     * @return String The extracted section content
     */
    private String extractSection(String fullSummary, String sectionName) {
        if (String.isBlank(fullSummary) || String.isBlank(sectionName)) {
            return null;
        }

        // Try to find section with number prefix (e.g., "1. EXECUTIVE SUMMARY")
        Pattern p = Pattern.compile('\\d+\\.\\s*' + sectionName + '\\s*(.+?)(?=\\d+\\.|$)');
        Matcher m = p.matcher(fullSummary);

        if (m.find()) {
            String content = m.group(1).trim();
            return content.length() > 5000 ? content.substring(0, 5000) : content;
        }

        return null;
    }

    /**
     * @description Determines the summary type based on trigger type
     * @param triggerType The trigger record type
     * @return String The summary type picklist value
     */
    private String getSummaryType(String triggerType) {
        if (triggerType == 'Account') {
            return 'Account Type Change';
        } else if (triggerType == 'Opportunity') {
            return 'Opportunity Analysis';
        } else if (triggerType == 'Lead') {
            return 'Lead Conversion';
        } else if (triggerType == 'Contract') {
            return 'Contract Review';
        } else if (triggerType == 'NPS') {
            return 'NPS Insights';
        }
        return 'Comprehensive';
    }

    /**
     * @description Gets the prompt template name based on trigger type
     * @param triggerType The trigger record type
     * @return String The prompt template name
     */
    private String getTemplateNameForTriggerType(String triggerType) {
        if (triggerType == 'Account') {
            return 'Account_Type_Change_Summary';
        } else if (triggerType == 'Opportunity') {
            return 'Opportunity_Analysis_Summary';
        } else if (triggerType == 'Lead') {
            return 'Lead_Conversion_Summary';
        } else if (triggerType == 'Contract') {
            return 'Contract_Review_Summary';
        }
        return 'Comprehensive_Account_Summary';
    }

    /**
     * @description Calculates the start date of the analysis period
     * @param data AccountSummaryData
     * @return Date The period start date
     */
    private Date calculatePeriodStart(AF_AccountSummaryPromptBuilder.AccountSummaryData data) {
        Date earliestDate = Date.today().addMonths(-12);

        // Check opportunities
        for (Opportunity opp : data.opportunities) {
            if (opp.CreatedDate != null && opp.CreatedDate.date() < earliestDate) {
                earliestDate = opp.CreatedDate.date();
            }
        }

        // Check leads
        for (Lead ld : data.leads) {
            if (ld.CreatedDate != null && ld.CreatedDate.date() < earliestDate) {
                earliestDate = ld.CreatedDate.date();
            }
        }

        return earliestDate;
    }

    /**
     * Helper methods to extract IDs from records
     */
    private List<String> getOpportunityIds(List<Opportunity> opps) {
        List<String> ids = new List<String>();
        for (Opportunity opp : opps) {
            ids.add(opp.Id);
        }
        return ids;
    }

    private List<String> getLeadIds(List<Lead> leads) {
        List<String> ids = new List<String>();
        for (Lead ld : leads) {
            ids.add(ld.Id);
        }
        return ids;
    }

    private List<String> getContractIds(List<Contract__c> contracts) {
        List<String> ids = new List<String>();
        for (Contract__c contract : contracts) {
            ids.add(contract.Id);
        }
        return ids;
    }

    private List<String> getNPSIds(List<NPS_Survey_Summary__c> npsList) {
        List<String> ids = new List<String>();
        for (NPS_Survey_Summary__c nps : npsList) {
            ids.add(nps.Id);
        }
        return ids;
    }

    /**
     * @description Serializes a list of IDs to JSON
     * @param ids List of record IDs
     * @return String JSON array of IDs
     */
    private String serializeIds(List<String> ids) {
        return ids.isEmpty() ? null : JSON.serialize(ids);
    }
}
