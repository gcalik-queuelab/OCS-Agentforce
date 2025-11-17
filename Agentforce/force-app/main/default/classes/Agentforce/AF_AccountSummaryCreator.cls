/**
 * @Name         AF_AccountSummaryCreator
 * @Author       Agentforce Implementation Team
 * @Date         2025
 * @Description  Invocable Apex class to manually trigger AI summary creation for Accounts.
 *               Provides methods to check for existing summaries and create new ones.
 *               Deletes existing summaries before creating new ones.
 */
public with sharing class AF_AccountSummaryCreator {

    /**
     * Input wrapper for invocable method
     */
    public class SummaryRequest {
        @InvocableVariable(label='Account ID' required=true)
        public Id accountId;
    }

    /**
     * Output wrapper for invocable method
     */
    public class SummaryResponse {
        @AuraEnabled @InvocableVariable
        public Boolean success;
        
        @AuraEnabled @InvocableVariable
        public String message;
        
        @AuraEnabled @InvocableVariable
        public Boolean hasExistingSummary;
    }

    /**
     * Creates or re-creates an AI summary for the given Account (AuraEnabled for LWC)
     * If summaries exist, they will be deleted first
     * @param accountId Account ID
     * @return SummaryResponse indicating success/failure
     */
    @AuraEnabled
    public static SummaryResponse createSummary(Id accountId) {
        SummaryResponse response = new SummaryResponse();
        
        try {
            // Query the Account record
            List<Account> accountRecords = [
                SELECT Id, Name, Type
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
            ];

            if (accountRecords.isEmpty()) {
                response.success = false;
                response.message = 'Account not found';
                return response;
            }

            Account account = accountRecords[0];

            // Delete existing summaries if any
            List<Account_Summary__c> existingSummaries = [
                SELECT Id
                FROM Account_Summary__c
                WHERE Account__c = :accountId
            ];

            Boolean hadExistingSummary = !existingSummaries.isEmpty();
            
            if (!existingSummaries.isEmpty()) {
                delete existingSummaries;
                System.debug('AF_AccountSummaryCreator: Deleted ' + existingSummaries.size() + ' existing summary(ies)');
            }

            // Gather account data
            Map<Id, AF_AccountSummaryPromptBuilder.AccountSummaryData> dataMap = 
                gatherAccountDataForManualGeneration(new List<Account>{ account });

            if (dataMap.isEmpty() || !dataMap.containsKey(accountId)) {
                response.success = false;
                response.message = 'Unable to gather account data for summary generation';
                return response;
            }

            // Enqueue the summary generation job
            System.enqueueJob(new AF_AccountSummaryQueueable(dataMap));

            response.success = true;
            response.message = 'Account Summary creation job has been queued. The summary will be generated shortly.';
            response.hasExistingSummary = hadExistingSummary;

        } catch (Exception e) {
            response.success = false;
            response.message = 'Error creating summary: ' + e.getMessage();
            response.hasExistingSummary = false;
            System.debug(LoggingLevel.ERROR, 'AF_AccountSummaryCreator.createSummary error: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
        }

        return response;
    }

    /**
     * Creates or re-creates an AI summary for the given Account (Invocable for Flow)
     * If summaries exist, they will be deleted first
     * @param requests List of SummaryRequest containing Account IDs
     * @return List of SummaryResponse indicating success/failure
     */
    @InvocableMethod(label='Create Account Summary' description='Creates or re-creates an AI-generated summary for an Account. Deletes existing summaries if present.')
    public static List<SummaryResponse> createSummaryInvocable(List<SummaryRequest> requests) {
        List<SummaryResponse> responses = new List<SummaryResponse>();

        for (SummaryRequest request : requests) {
            responses.add(createSummary(request.accountId));
        }

        return responses;
    }

    /**
     * @description Gathers all related data for account summary generation (manual trigger)
     * Uses Comprehensive summary type for manual generation
     * @param accounts List of Account records
     * @return Map of Account ID to AccountSummaryData
     */
    private static Map<Id, AF_AccountSummaryPromptBuilder.AccountSummaryData> gatherAccountDataForManualGeneration(
        List<Account> accounts
    ) {
        Map<Id, AF_AccountSummaryPromptBuilder.AccountSummaryData> dataMap =
            new Map<Id, AF_AccountSummaryPromptBuilder.AccountSummaryData>();

        Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();

        // Query accounts with necessary fields
        List<Account> accountsWithFields = [
            SELECT Id, Name, AccountNumber, Type, Industry, AnnualRevenue,
                   NumberOfEmployees, Description, OwnerId, Owner.Name
            FROM Account
            WHERE Id IN :accountIds
        ];

        // Query related opportunities (open + closed in last 12 months)
        Date twelveMonthsAgo = Date.today().addMonths(-12);
        Map<Id, List<Opportunity>> opportunitiesByAccount = new Map<Id, List<Opportunity>>();

        for (Opportunity opp : [
            SELECT Id, Name, AccountId, StageName, Amount, CloseDate, Probability,
                   Description, CreatedDate
            FROM Opportunity
            WHERE AccountId IN :accountIds
            AND (IsClosed = false OR CloseDate >= :twelveMonthsAgo)
            ORDER BY CreatedDate DESC
            LIMIT 200
        ]) {
            if (!opportunitiesByAccount.containsKey(opp.AccountId)) {
                opportunitiesByAccount.put(opp.AccountId, new List<Opportunity>());
            }
            opportunitiesByAccount.get(opp.AccountId).add(opp);
        }

        // Query related leads (last 6 months)
        Date sixMonthsAgo = Date.today().addMonths(-6);
        Map<Id, List<Lead>> leadsByAccount = new Map<Id, List<Lead>>();

        for (Lead ld : [
            SELECT Id, Name, Company, Status, LeadSource, IsConverted, ConvertedDate,
                   ConvertedAccountId, Description, CreatedDate
            FROM Lead
            WHERE ConvertedAccountId IN :accountIds
            AND CreatedDate >= :sixMonthsAgo
            ORDER BY CreatedDate DESC
            LIMIT 100
        ]) {
            if (!leadsByAccount.containsKey(ld.ConvertedAccountId)) {
                leadsByAccount.put(ld.ConvertedAccountId, new List<Lead>());
            }
            leadsByAccount.get(ld.ConvertedAccountId).add(ld);
        }

        // Query related contracts
        Map<Id, List<Contract__c>> contractsByAccount = new Map<Id, List<Contract__c>>();

        for (Contract__c contract : [
            SELECT Id, Name, Account__c, Status__c, Contract_Start_Date__c,
                   Contract_End_Date__c, Description__c
            FROM Contract__c
            WHERE Account__c IN :accountIds
            ORDER BY CreatedDate DESC
            LIMIT 100
        ]) {
            if (!contractsByAccount.containsKey(contract.Account__c)) {
                contractsByAccount.put(contract.Account__c, new List<Contract__c>());
            }
            contractsByAccount.get(contract.Account__c).add(contract);
        }

        // Query recent NPS summaries
        Map<Id, List<NPS_Survey_Summary__c>> npsByAccount = new Map<Id, List<NPS_Survey_Summary__c>>();

        for (NPS_Survey_Summary__c nps : [
            SELECT Id, Name, Account__c, NPS_Score__c, Survey_Date__c,
                   Sentiment_Analysis__c, Summary_Generation_Date__c, CreatedDate, AI_Summary__c
            FROM NPS_Survey_Summary__c
            WHERE Account__c IN :accountIds
            ORDER BY Summary_Generation_Date__c DESC
            LIMIT 50
        ]) {
            if (!npsByAccount.containsKey(nps.Account__c)) {
                npsByAccount.put(nps.Account__c, new List<NPS_Survey_Summary__c>());
            }
            npsByAccount.get(nps.Account__c).add(nps);
        }

        // Build data map for each account
        for (Account acc : accountsWithFields) {
            AF_AccountSummaryPromptBuilder.AccountSummaryData data = 
                new AF_AccountSummaryPromptBuilder.AccountSummaryData();
            
            data.account = acc;
            data.opportunities = opportunitiesByAccount.get(acc.Id) != null ? 
                opportunitiesByAccount.get(acc.Id) : new List<Opportunity>();
            data.leads = leadsByAccount.get(acc.Id) != null ? 
                leadsByAccount.get(acc.Id) : new List<Lead>();
            data.contracts = contractsByAccount.get(acc.Id) != null ? 
                contractsByAccount.get(acc.Id) : new List<Contract__c>();
            data.npsSummaries = npsByAccount.get(acc.Id) != null ? 
                npsByAccount.get(acc.Id) : new List<NPS_Survey_Summary__c>();
            data.triggerType = 'Comprehensive'; // Manual generation uses Comprehensive type
            data.previousAccountType = null; // Not applicable for manual generation

            dataMap.put(acc.Id, data);
        }

        return dataMap;
    }
}

