/**
 * @Name         AF_NPSPromptBuilder
 * @Author       Agentforce Implementation Team
 * @Date         2025-01-15
 * @Description  Utility class to build structured prompts for Agentforce AI summary generation
 *               from NPS Survey and Response data
 */
public with sharing class AF_NPSPromptBuilder {

    /**
     * Builds a comprehensive prompt string from NPS Survey and its responses
     * @param nps The NPS Survey record with related Account, Contact, Surveyor data
     * @param responses List of NPS Response records for this survey
     * @return Formatted prompt string ready for Agentforce
     */
    public static String buildPromptData(NPS__c nps, List<NPS_Response__c> responses) {
        String prompt = '';

        // Header Section
        prompt += '===== NPS SURVEY DATA =====\n\n';

        // Survey Metadata
        prompt += 'SURVEY INFORMATION:\n';
        prompt += 'Survey Number: ' + nps.Name + '\n';

        if (nps.Account__c != null && nps.Account__r != null) {
            prompt += 'Account: ' + nps.Account__r.Name + '\n';
        }

        if (nps.NPS_Contact__c != null && nps.NPS_Contact__r != null) {
            prompt += 'Contact: ' + nps.NPS_Contact__r.Name + '\n';
        }

        if (nps.NPS_Surveyor__c != null && nps.NPS_Surveyor__r != null) {
            prompt += 'Surveyor: ' + nps.NPS_Surveyor__r.Name + '\n';
        }

        if (nps.Visit_Start__c != null) {
            prompt += 'Survey Date: ' + nps.Visit_Start__c.format('yyyy-MM-dd') + '\n';
        }

        if (nps.Survey_Category__c != null) {
            prompt += 'Category: ' + nps.Survey_Category__c + '\n';
        }

        prompt += '\n';

        // Scores Section
        prompt += 'OVERALL SCORES:\n';

        if (nps.Recommend_Us_Score__c != null) {
            prompt += 'NPS Recommendation Score: ' + nps.Recommend_Us_Score__c + ' / 10\n';
        }

        if (nps.Average_Score__c != null) {
            prompt += 'Average Score: ' + nps.Average_Score__c + '\n';
        }

        if (nps.Total_NPS_Score__c != null) {
            prompt += 'Total Score: ' + nps.Total_NPS_Score__c + '\n';
        }

        if (nps.Number_of_NPS_Responses__c != null) {
            prompt += 'Number of Responses: ' + nps.Number_of_NPS_Responses__c + '\n';
        }

        prompt += '\n';

        // Responses Section
        if (responses != null && !responses.isEmpty()) {
            prompt += 'DETAILED RESPONSES:\n';
            prompt += '---\n';

            for (NPS_Response__c response : responses) {
                if (response.Question__c != null) {
                    prompt += '\nQuestion: ' + response.Question__c + '\n';
                }

                if (response.Score__c != null) {
                    prompt += 'Score: ' + response.Score__c + ' / 10\n';
                }

                if (String.isNotBlank(response.Answer__c)) {
                    prompt += 'Answer: ' + response.Answer__c + '\n';
                }

                if (String.isNotBlank(response.Suggestion_for_improvement__c)) {
                    prompt += 'Suggestions for Improvement: ' + response.Suggestion_for_improvement__c + '\n';
                }

                prompt += '---\n';
            }

            prompt += '\n';
        }

        // Additional Comments
        if (String.isNotBlank(nps.Comments__c)) {
            prompt += 'OVERALL COMMENTS:\n';
            prompt += nps.Comments__c + '\n\n';
        }

        if (String.isNotBlank(nps.Visiting_Comments__c)) {
            prompt += 'VISITING COMMENTS:\n';
            prompt += nps.Visiting_Comments__c + '\n\n';
        }

        // Instructions for AI
        prompt += '===== SUMMARY REQUEST =====\n\n';
        prompt += 'Please analyze the above NPS survey data and provide a comprehensive summary in English that includes:\n\n';
        prompt += '1. EXECUTIVE SUMMARY (2-3 sentences highlighting overall sentiment and key takeaways)\n\n';
        prompt += '2. KEY STRENGTHS (bullet points of positive feedback and high-scoring areas)\n\n';
        prompt += '3. AREAS FOR IMPROVEMENT (bullet points of concerns and low-scoring areas)\n\n';
        prompt += '4. SENTIMENT ANALYSIS (Overall: Positive, Neutral, Negative, or Mixed)\n\n';
        prompt += '5. RECOMMENDED ACTIONS (prioritized list of specific, actionable next steps)\n\n';
        prompt += '6. FOLLOW-UP REQUIRED (Yes/No with brief explanation)\n\n';
        prompt += 'Please format the summary in a professional, concise manner suitable for business stakeholders.\n';

        return prompt;
    }

    /**
     * Validates that NPS record has minimum required data for summary generation
     * @param nps The NPS Survey record
     * @param responses List of NPS Response records
     * @return true if data is sufficient, false otherwise
     */
    public static Boolean hasRequiredData(NPS__c nps, List<NPS_Response__c> responses) {
        if (nps == null) {
            return false;
        }

        // Must have at least one response to generate meaningful summary
        if (responses == null || responses.isEmpty()) {
            return false;
        }

        // Must have Status = Closed
        if (nps.Status__c != 'Closed') {
            return false;
        }

        return true;
    }
}
