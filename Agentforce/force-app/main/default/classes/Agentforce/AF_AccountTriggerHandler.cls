/**
 * @description Trigger handler for Account object to generate Account Summaries
 * @author Agentforce POC
 * @date 2025
 */
public with sharing class AF_AccountTriggerHandler {

    /**
     * @description Handles after update trigger logic
     * @param newList List of new Account records
     * @param oldMap Map of old Account records
     */
    public static void handleAfterUpdate(List<Account> newList, Map<Id, Account> oldMap) {
        Set<Id> accountsToSummarize = new Set<Id>();
        Map<Id, String> accountPreviousTypes = new Map<Id, String>();

        // Detect Account Type changes
        for (Account acc : newList) {
            Account oldAcc = oldMap.get(acc.Id);

            // Check if Type changed
            if (acc.Type != oldAcc.Type && acc.Type != null) {
                accountsToSummarize.add(acc.Id);
                accountPreviousTypes.put(acc.Id, oldAcc.Type);
            }
        }

        // Filter out accounts that had a summary generated in last 24 hours
        if (!accountsToSummarize.isEmpty()) {
            Set<Id> eligibleAccounts = AF_AccountSummaryDuplicateChecker.filterEligibleAccounts(accountsToSummarize);

            if (!eligibleAccounts.isEmpty()) {
                generateAccountSummariesAsync(eligibleAccounts, accountPreviousTypes);
            } else {
                System.debug(LoggingLevel.INFO,
                    'All accounts filtered out due to 24-hour cooldown: ' + accountsToSummarize);
            }
        }
    }

    /**
     * @description Generates account summaries asynchronously
     * @param accountIds Set of Account IDs to generate summaries for
     * @param previousTypes Map of Account IDs to their previous Type values
     */
    private static void generateAccountSummariesAsync(Set<Id> accountIds, Map<Id, String> previousTypes) {
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
            Map<Id, AF_AccountSummaryPromptBuilder.AccountSummaryData> dataMap = gatherAccountData(accounts, previousTypes);

            if (!dataMap.isEmpty()) {
                // Enqueue async job
                System.enqueueJob(new AF_AccountSummaryQueueable(dataMap));
                System.debug(LoggingLevel.INFO, 'Enqueued Account Summary generation for ' + dataMap.size() + ' accounts');
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in generateAccountSummariesAsync: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack Trace: ' + e.getStackTraceString());
        }
    }

    /**
     * @description Gathers all related data for account summary generation
     * @param accounts List of Account records
     * @param previousTypes Map of Account IDs to previous Type values
     * @return Map of Account ID to AccountSummaryData
     */
    private static Map<Id, AF_AccountSummaryPromptBuilder.AccountSummaryData> gatherAccountData(
        List<Account> accounts,
        Map<Id, String> previousTypes
    ) {
        Map<Id, AF_AccountSummaryPromptBuilder.AccountSummaryData> dataMap =
            new Map<Id, AF_AccountSummaryPromptBuilder.AccountSummaryData>();

        Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();

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

        // Note: Leads link to Account via ConvertedAccountId (only converted leads)
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
            data.triggerType = 'Account';
            data.previousAccountType = previousTypes.get(acc.Id);

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
