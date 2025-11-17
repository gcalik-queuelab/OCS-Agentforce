/**
 * @description Utility class for building prompts for Account Summary AI generation
 * @author Agentforce POC
 * @date 2025
 */
public with sharing class AF_AccountSummaryPromptBuilder {

    /**
     * @description Wrapper class to hold all data needed for summary generation
     */
    public class AccountSummaryData {
        public Account account { get; set; }
        public List<Opportunity> opportunities { get; set; }
        public List<Lead> leads { get; set; }
        public List<Contract__c> contracts { get; set; }
        public List<NPS_Survey_Summary__c> npsSummaries { get; set; }
        public String triggerType { get; set; }
        public String previousAccountType { get; set; }

        public AccountSummaryData() {
            this.opportunities = new List<Opportunity>();
            this.leads = new List<Lead>();
            this.contracts = new List<Contract__c>();
            this.npsSummaries = new List<NPS_Survey_Summary__c>();
        }
    }

    /**
     * @description Builds formatted prompt data for AI processing
     * @param data AccountSummaryData wrapper containing all relevant information
     * @return String formatted prompt for AI
     */
    public static String buildPromptData(AccountSummaryData data) {
        if (!hasRequiredData(data)) {
            throw new IllegalArgumentException('Account data is required for summary generation');
        }

        String prompt = '';

        // Account Information Section
        prompt += '===== ACCOUNT INFORMATION =====\n\n';
        prompt += buildAccountSection(data.account, data.previousAccountType);

        // Related Records Sections
        if (!data.opportunities.isEmpty()) {
            prompt += '\n===== OPPORTUNITIES (' + data.opportunities.size() + ') =====\n';
            prompt += buildOpportunitiesSection(data.opportunities);
        }

        if (!data.leads.isEmpty()) {
            prompt += '\n===== LEADS (' + data.leads.size() + ') =====\n';
            prompt += buildLeadsSection(data.leads);
        }

        if (!data.contracts.isEmpty()) {
            prompt += '\n===== CONTRACTS (' + data.contracts.size() + ') =====\n';
            prompt += buildContractsSection(data.contracts);
        }

        if (!data.npsSummaries.isEmpty()) {
            prompt += '\n===== NPS INSIGHTS (' + data.npsSummaries.size() + ' Recent Summaries) =====\n';
            prompt += buildNPSSection(data.npsSummaries);
        }

        // Analysis Request Section
        prompt += '\n===== ANALYSIS REQUEST =====\n\n';
        prompt += buildAnalysisRequest(data.triggerType);

        return prompt;
    }

    /**
     * @description Validates that required data is present
     * @param data AccountSummaryData to validate
     * @return Boolean true if required data exists
     */
    public static Boolean hasRequiredData(AccountSummaryData data) {
        return data != null && data.account != null && data.account.Id != null;
    }

    /**
     * @description Builds the account information section
     * @param acc Account record
     * @param previousType Previous account type (if applicable)
     * @return String formatted account section
     */
    private static String buildAccountSection(Account acc, String previousType) {
        String section = 'Account Name: ' + (acc.Name != null ? acc.Name : 'N/A') + '\n';
        section += 'Account Number: ' + (acc.AccountNumber != null ? acc.AccountNumber : 'N/A') + '\n';
        section += 'Account Type: ' + (acc.Type != null ? acc.Type : 'N/A') + '\n';

        if (String.isNotBlank(previousType)) {
            section += 'Previous Account Type: ' + previousType + '\n';
        }

        section += 'Industry: ' + (acc.Industry != null ? acc.Industry : 'N/A') + '\n';
        section += 'Annual Revenue: ' + (acc.AnnualRevenue != null ? String.valueOf(acc.AnnualRevenue) : 'N/A') + '\n';
        section += 'Number of Employees: ' + (acc.NumberOfEmployees != null ? String.valueOf(acc.NumberOfEmployees) : 'N/A') + '\n';
        section += 'Account Owner: ' + (acc.Owner != null && acc.Owner.Name != null ? acc.Owner.Name : 'N/A') + '\n';
        section += 'Description: ' + (acc.Description != null ? acc.Description : 'N/A') + '\n';

        return section;
    }

    /**
     * @description Builds the opportunities section
     * @param opps List of Opportunity records
     * @return String formatted opportunities section
     */
    private static String buildOpportunitiesSection(List<Opportunity> opps) {
        String section = '';
        Integer count = 0;

        for (Opportunity opp : opps) {
            count++;
            if (count > 20) { // Limit to prevent prompt size issues
                section += '\n... and ' + (opps.size() - 20) + ' more opportunities\n';
                break;
            }

            section += '\n--- Opportunity ' + count + ' ---\n';
            section += 'Name: ' + (opp.Name != null ? opp.Name : 'N/A') + '\n';
            section += 'Stage: ' + (opp.StageName != null ? opp.StageName : 'N/A') + '\n';
            section += 'Amount: ' + (opp.Amount != null ? String.valueOf(opp.Amount) : 'N/A') + '\n';
            section += 'Close Date: ' + (opp.CloseDate != null ? String.valueOf(opp.CloseDate) : 'N/A') + '\n';
            section += 'Probability: ' + (opp.Probability != null ? String.valueOf(opp.Probability) + '%' : 'N/A') + '\n';
            section += 'Description: ' + (opp.Description != null ? opp.Description.left(200) : 'N/A') + '\n';
        }

        return section;
    }

    /**
     * @description Builds the leads section
     * @param leads List of Lead records
     * @return String formatted leads section
     */
    private static String buildLeadsSection(List<Lead> leads) {
        String section = '';
        Integer count = 0;

        for (Lead ld : leads) {
            count++;
            if (count > 20) { // Limit to prevent prompt size issues
                section += '\n... and ' + (leads.size() - 20) + ' more leads\n';
                break;
            }

            section += '\n--- Lead ' + count + ' ---\n';
            section += 'Name: ' + (ld.Name != null ? ld.Name : 'N/A') + '\n';
            section += 'Company: ' + (ld.Company != null ? ld.Company : 'N/A') + '\n';
            section += 'Status: ' + (ld.Status != null ? ld.Status : 'N/A') + '\n';
            section += 'Lead Source: ' + (ld.LeadSource != null ? ld.LeadSource : 'N/A') + '\n';
            section += 'Converted: ' + (ld.IsConverted ? 'Yes' : 'No') + '\n';
            if (ld.IsConverted && ld.ConvertedDate != null) {
                section += 'Converted Date: ' + String.valueOf(ld.ConvertedDate) + '\n';
            }
            section += 'Description: ' + (ld.Description != null ? ld.Description.left(200) : 'N/A') + '\n';
        }

        return section;
    }

    /**
     * @description Builds the contracts section
     * @param contracts List of Contract__c records
     * @return String formatted contracts section
     */
    private static String buildContractsSection(List<Contract__c> contracts) {
        String section = '';
        Integer count = 0;

        for (Contract__c contract : contracts) {
            count++;
            if (count > 15) { // Limit to prevent prompt size issues
                section += '\n... and ' + (contracts.size() - 15) + ' more contracts\n';
                break;
            }

            section += '\n--- Contract ' + count + ' ---\n';
            section += 'Name: ' + (contract.Name != null ? contract.Name : 'N/A') + '\n';
            section += 'Status: ' + (contract.Status__c != null ? contract.Status__c : 'N/A') + '\n';

            if (contract.Contract_Start_Date__c != null) {
                section += 'Start Date: ' + String.valueOf(contract.Contract_Start_Date__c) + '\n';
            }
            if (contract.Contract_End_Date__c != null) {
                section += 'End Date: ' + String.valueOf(contract.Contract_End_Date__c) + '\n';
            }

            section += 'Description: ' + (contract.Description__c != null ? contract.Description__c.left(200) : 'N/A') + '\n';
        }

        return section;
    }

    /**
     * @description Builds the NPS insights section
     * @param npsSummaries List of NPS_Survey_Summary__c records
     * @return String formatted NPS section
     */
    private static String buildNPSSection(List<NPS_Survey_Summary__c> npsSummaries) {
        String section = '';
        Integer count = 0;

        for (NPS_Survey_Summary__c nps : npsSummaries) {
            count++;
            if (count > 10) { // Limit to prevent prompt size issues
                section += '\n... and ' + (npsSummaries.size() - 10) + ' more NPS summaries\n';
                break;
            }

            section += '\n--- NPS Summary ' + count + ' ---\n';
            section += 'Survey Date: ' + (nps.CreatedDate != null ? String.valueOf(nps.CreatedDate.date()) : 'N/A') + '\n';
            section += 'NPS Score: ' + (nps.NPS_Score__c != null ? String.valueOf(nps.NPS_Score__c) : 'N/A') + '\n';

            if (nps.Sentiment_Analysis__c != null) {
                section += 'Sentiment: ' + nps.Sentiment_Analysis__c + '\n';
            }

            if (nps.AI_Summary__c != null) {
                section += 'Summary: ' + nps.AI_Summary__c.left(500) + '\n';
            }
        }

        return section;
    }

    /**
     * @description Builds the analysis request instructions for AI
     * @param triggerType Type of record that triggered the summary
     * @return String formatted analysis request
     */
    private static String buildAnalysisRequest(String triggerType) {
        String request = 'Please analyze this account comprehensively based on the data provided above.\n\n';
        request += 'You MUST generate this summary in English, regardless of source data language.\n\n';
        request += 'Provide the following sections in your analysis:\n\n';

        request += '1. EXECUTIVE SUMMARY (2-3 sentences)\n';
        request += '   - High-level overview of the account status and key findings\n';
        request += '   - Most critical insight requiring immediate attention\n\n';

        request += '2. KEY INSIGHTS\n';
        request += '   - Main findings from the data analysis\n';
        request += '   - Notable patterns or trends\n';
        request += '   - Significant changes or developments\n\n';

        request += '3. OPPORTUNITIES IDENTIFIED\n';
        request += '   - Growth or expansion possibilities\n';
        request += '   - Upsell or cross-sell potential\n';
        request += '   - Strategic recommendations\n\n';

        request += '4. RISK FACTORS\n';
        request += '   - Concerns or warning signs\n';
        request += '   - Churn indicators\n';
        request += '   - Areas requiring mitigation\n\n';

        request += '5. ACTION RECOMMENDATIONS\n';
        request += '   - Prioritized next steps\n';
        request += '   - Specific actions for account team\n';
        request += '   - Timeline suggestions\n\n';

        if (String.isNotBlank(triggerType)) {
            request += 'NOTE: This summary was triggered by: ' + triggerType + '\n';
            request += 'Please give special attention to changes related to this trigger.\n\n';
        }

        request += 'Format your response using markdown for readability.\n';
        request += 'Target length: 400-600 words total.\n';

        return request;
    }
}
