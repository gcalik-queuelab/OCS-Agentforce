/**
 * @description Apex controller for AccountSummaryRelatedList Lightning Web Component
 * Retrieves Account Summary records related to an Account
 */
public with sharing class AccountSummaryRelatedListController {

    /**
     * @description Retrieves Account Summary records related to an Account
     * @param accountId The ID of the Account record
     * @param maxRecords Maximum number of records to return
     * @return List of Account Summary records with related data
     */
    @AuraEnabled(cacheable=true)
    public static List<AccountSummaryWrapper> getRelatedSummariesByAccount(String accountId, Integer maxRecords) {
        List<AccountSummaryWrapper> summaries = new List<AccountSummaryWrapper>();

        if (String.isBlank(accountId)) {
            return summaries;
        }

        try {
            List<Account_Summary__c> summaryRecords = [
                SELECT Id, Name, Summary_Type__c, Summary_Generation_Date__c,
                       Generation_Status__c, Sentiment_Analysis__c, Priority_Level__c,
                       Created_By_Agentforce__c,
                       CreatedBy.Name, CreatedDate, LastModifiedDate
                FROM Account_Summary__c
                WHERE Account__c = :accountId
                ORDER BY Summary_Generation_Date__c DESC NULLS LAST, CreatedDate DESC
                LIMIT :maxRecords
            ];

            for (Account_Summary__c summary : summaryRecords) {
                AccountSummaryWrapper wrapper = new AccountSummaryWrapper();
                wrapper.id = summary.Id;
                wrapper.name = summary.Name;
                wrapper.summaryType = summary.Summary_Type__c;
                wrapper.summaryGenerationDate = summary.Summary_Generation_Date__c;
                wrapper.generationStatus = summary.Generation_Status__c;
                wrapper.sentimentAnalysis = summary.Sentiment_Analysis__c;
                wrapper.priorityLevel = summary.Priority_Level__c;
                wrapper.createdByAgentforce = summary.Created_By_Agentforce__c == true;
                wrapper.createdByName = summary.CreatedBy != null ? summary.CreatedBy.Name : '';
                wrapper.createdDate = summary.CreatedDate;
                wrapper.lastModifiedDate = summary.LastModifiedDate;

                summaries.add(wrapper);
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving Account Summaries: ' + e.getMessage());
        }

        return summaries;
    }

    /**
     * @description Wrapper class for Account Summary data
     */
    public class AccountSummaryWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String summaryType;
        @AuraEnabled public DateTime summaryGenerationDate;
        @AuraEnabled public String generationStatus;
        @AuraEnabled public String sentimentAnalysis;
        @AuraEnabled public String priorityLevel;
        @AuraEnabled public Boolean createdByAgentforce;
        @AuraEnabled public String createdByName;
        @AuraEnabled public DateTime createdDate;
        @AuraEnabled public DateTime lastModifiedDate;
    }
}
