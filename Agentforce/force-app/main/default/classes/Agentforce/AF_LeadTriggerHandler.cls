/**
 * @description Trigger handler for Lead object to generate Account Summaries
 * @author Agentforce POC
 * @date 2025
 */
public with sharing class AF_LeadTriggerHandler {

    /**
     * @description Handles after update trigger logic
     * @param newList List of new Lead records
     * @param oldMap Map of old Lead records
     */
    public static void handleAfterUpdate(List<Lead> newList, Map<Id, Lead> oldMap) {
        Set<Id> accountsToSummarize = new Set<Id>();

        // Detect lead conversions and status changes
        for (Lead ld : newList) {
            Lead oldLead = oldMap.get(ld.Id);

            // Lead was just converted
            if (ld.IsConverted && !oldLead.IsConverted && ld.ConvertedAccountId != null) {
                accountsToSummarize.add(ld.ConvertedAccountId);
                continue;
            }

            // Status change on converted lead (related to account)
            if (ld.ConvertedAccountId != null && ld.Status != oldLead.Status) {
                accountsToSummarize.add(ld.ConvertedAccountId);
            }
        }

        processSummaryGeneration(accountsToSummarize);
    }

    /**
     * @description Processes summary generation with duplicate checking
     * @param accountIds Set of Account IDs
     */
    private static void processSummaryGeneration(Set<Id> accountIds) {
        if (accountIds.isEmpty()) {
            return;
        }

        // Filter out accounts that had a summary generated in last 24 hours
        Set<Id> eligibleAccounts = AF_AccountSummaryDuplicateChecker.filterEligibleAccounts(accountIds);

        if (!eligibleAccounts.isEmpty()) {
            generateAccountSummariesAsync(eligibleAccounts);
        } else {
            System.debug(LoggingLevel.INFO,
                'All accounts filtered out due to 24-hour cooldown: ' + accountIds);
        }
    }

    /**
     * @description Generates account summaries asynchronously
     * @param accountIds Set of Account IDs to generate summaries for
     */
    private static void generateAccountSummariesAsync(Set<Id> accountIds) {
        try {
            // Query accounts with necessary fields
            List<Account> accounts = [
                SELECT Id, Name, AccountNumber, Type, Industry, AnnualRevenue,
                       NumberOfEmployees, Description, OwnerId, Owner.Name
                FROM Account
                WHERE Id IN :accountIds
            ];

            if (accounts.isEmpty()) {
                System.debug(LoggingLevel.WARN, 'No accounts found for IDs: ' + accountIds);
                return;
            }

            // Gather related data for each account
            Map<Id, AF_AccountSummaryPromptBuilder.AccountSummaryData> dataMap = gatherAccountData(accounts);

            if (!dataMap.isEmpty()) {
                // Enqueue async job
                System.enqueueJob(new AF_AccountSummaryQueueable(dataMap));
                System.debug(LoggingLevel.INFO,
                    'Enqueued Account Summary generation for ' + dataMap.size() + ' accounts from Lead');
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in generateAccountSummariesAsync: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack Trace: ' + e.getStackTraceString());
        }
    }

    /**
     * @description Gathers all related data for account summary generation
     * @param accounts List of Account records
     * @return Map of Account ID to AccountSummaryData
     */
    private static Map<Id, AF_AccountSummaryPromptBuilder.AccountSummaryData> gatherAccountData(
        List<Account> accounts
    ) {
        Map<Id, AF_AccountSummaryPromptBuilder.AccountSummaryData> dataMap =
            new Map<Id, AF_AccountSummaryPromptBuilder.AccountSummaryData>();

        Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();

        // Query related opportunities
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

        // Query related leads
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
            SELECT Id, Account__c, NPS_Score__c, Sentiment_Analysis__c,
                   AI_Summary__c, CreatedDate
            FROM NPS_Survey_Summary__c
            WHERE Account__c IN :accountIds
            ORDER BY CreatedDate DESC
            LIMIT 50
        ]) {
            if (!npsByAccount.containsKey(nps.Account__c)) {
                npsByAccount.put(nps.Account__c, new List<NPS_Survey_Summary__c>());
            }
            npsByAccount.get(nps.Account__c).add(nps);
        }

        // Build data wrappers for each account
        for (Account acc : accounts) {
            AF_AccountSummaryPromptBuilder.AccountSummaryData data =
                new AF_AccountSummaryPromptBuilder.AccountSummaryData();

            data.account = acc;
            data.triggerType = 'Lead';

            // Add related records
            data.opportunities = opportunitiesByAccount.containsKey(acc.Id) ?
                opportunitiesByAccount.get(acc.Id) : new List<Opportunity>();
            data.leads = leadsByAccount.containsKey(acc.Id) ?
                leadsByAccount.get(acc.Id) : new List<Lead>();
            data.contracts = contractsByAccount.containsKey(acc.Id) ?
                contractsByAccount.get(acc.Id) : new List<Contract__c>();
            data.npsSummaries = npsByAccount.containsKey(acc.Id) ?
                npsByAccount.get(acc.Id) : new List<NPS_Survey_Summary__c>();

            dataMap.put(acc.Id, data);
        }

        return dataMap;
    }
}
