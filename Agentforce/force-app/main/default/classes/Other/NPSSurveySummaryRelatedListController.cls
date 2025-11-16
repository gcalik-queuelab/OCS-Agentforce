/**
 * @description Apex controller for NPSSurveySummaryRelatedList Lightning Web Component
 * Retrieves NPS Survey Summary records related to an NPS Survey or Account
 */
public with sharing class NPSSurveySummaryRelatedListController {
    
    /**
     * @description Retrieves NPS Survey Summary records related to an NPS Survey
     * @param npsSurveyId The ID of the NPS Survey record
     * @param maxRecords Maximum number of records to return
     * @return List of NPS Survey Summary records with related data
     */
    @AuraEnabled(cacheable=true)
    public static List<NPSSurveySummaryWrapper> getRelatedSummariesByNPS(String npsSurveyId, Integer maxRecords) {
        List<NPSSurveySummaryWrapper> summaries = new List<NPSSurveySummaryWrapper>();
        
        if (String.isBlank(npsSurveyId)) {
            return summaries;
        }
        
        try {
            List<NPS_Survey_Summary__c> summaryRecords = [
                SELECT Id, Name, NPS_Score__c, Survey_Date__c, Sentiment_Analysis__c, 
                       Follow_Up_Required__c, Summary_Generation_Date__c, Account__r.Name,
                       CreatedBy.Name, CreatedDate
                FROM NPS_Survey_Summary__c
                WHERE NPS_Survey__c = :npsSurveyId
                ORDER BY Summary_Generation_Date__c DESC NULLS LAST, CreatedDate DESC
                LIMIT :maxRecords
            ];
            
            for (NPS_Survey_Summary__c summary : summaryRecords) {
                NPSSurveySummaryWrapper wrapper = new NPSSurveySummaryWrapper();
                wrapper.id = summary.Id;
                wrapper.name = summary.Name;
                wrapper.npsScore = summary.NPS_Score__c;
                wrapper.surveyDate = summary.Survey_Date__c;
                wrapper.sentimentAnalysis = summary.Sentiment_Analysis__c;
                wrapper.followUpRequired = summary.Follow_Up_Required__c == true;
                wrapper.summaryGenerationDate = summary.Summary_Generation_Date__c;
                wrapper.accountName = summary.Account__r != null ? summary.Account__r.Name : '';
                wrapper.createdByName = summary.CreatedBy != null ? summary.CreatedBy.Name : '';
                wrapper.createdDate = summary.CreatedDate;
                
                summaries.add(wrapper);
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving NPS Survey Summaries: ' + e.getMessage());
        }
        
        return summaries;
    }
    
    /**
     * @description Retrieves NPS Survey Summary records related to an Account
     * @param accountId The ID of the Account record
     * @param maxRecords Maximum number of records to return
     * @return List of NPS Survey Summary records with related data
     */
    @AuraEnabled(cacheable=true)
    public static List<NPSSurveySummaryWrapper> getRelatedSummariesByAccount(String accountId, Integer maxRecords) {
        List<NPSSurveySummaryWrapper> summaries = new List<NPSSurveySummaryWrapper>();
        
        if (String.isBlank(accountId)) {
            return summaries;
        }
        
        try {
            List<NPS_Survey_Summary__c> summaryRecords = [
                SELECT Id, Name, NPS_Score__c, Survey_Date__c, Sentiment_Analysis__c, 
                       Follow_Up_Required__c, Summary_Generation_Date__c, NPS_Survey__r.Name,
                       CreatedBy.Name, CreatedDate
                FROM NPS_Survey_Summary__c
                WHERE Account__c = :accountId
                ORDER BY Summary_Generation_Date__c DESC NULLS LAST, CreatedDate DESC
                LIMIT :maxRecords
            ];
            
            for (NPS_Survey_Summary__c summary : summaryRecords) {
                NPSSurveySummaryWrapper wrapper = new NPSSurveySummaryWrapper();
                wrapper.id = summary.Id;
                wrapper.name = summary.Name;
                wrapper.npsScore = summary.NPS_Score__c;
                wrapper.surveyDate = summary.Survey_Date__c;
                wrapper.sentimentAnalysis = summary.Sentiment_Analysis__c;
                wrapper.followUpRequired = summary.Follow_Up_Required__c == true;
                wrapper.summaryGenerationDate = summary.Summary_Generation_Date__c;
                wrapper.npsSurveyName = summary.NPS_Survey__r != null ? summary.NPS_Survey__r.Name : '';
                wrapper.createdByName = summary.CreatedBy != null ? summary.CreatedBy.Name : '';
                wrapper.createdDate = summary.CreatedDate;
                
                summaries.add(wrapper);
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving NPS Survey Summaries: ' + e.getMessage());
        }
        
        return summaries;
    }
    
    /**
     * @description Wrapper class for NPS Survey Summary data
     */
    public class NPSSurveySummaryWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public Decimal npsScore;
        @AuraEnabled public Date surveyDate;
        @AuraEnabled public String sentimentAnalysis;
        @AuraEnabled public Boolean followUpRequired;
        @AuraEnabled public DateTime summaryGenerationDate;
        @AuraEnabled public String accountName;
        @AuraEnabled public String npsSurveyName;
        @AuraEnabled public String createdByName;
        @AuraEnabled public DateTime createdDate;
    }
}

