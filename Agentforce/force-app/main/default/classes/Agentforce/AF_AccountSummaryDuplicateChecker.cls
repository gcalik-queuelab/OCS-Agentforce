/**
 * @description Helper class to prevent duplicate Account Summary generation within 24 hours
 * @author Agentforce POC
 * @date 2025
 */
public with sharing class AF_AccountSummaryDuplicateChecker {

    private static final Integer COOLDOWN_HOURS = 24;

    /**
     * @description Checks if an account can have a new summary generated (24-hour cooldown)
     * @param accountId The Account ID to check
     * @return Boolean true if summary can be generated, false if within cooldown period
     */
    public static Boolean canGenerateSummary(Id accountId) {
        if (accountId == null) {
            return false;
        }

        DateTime cutoffTime = DateTime.now().addHours(-COOLDOWN_HOURS);

        List<Account_Summary__c> recentSummaries = [
            SELECT Id, CreatedDate
            FROM Account_Summary__c
            WHERE Account__c = :accountId
            AND CreatedDate >= :cutoffTime
            AND Created_By_Agentforce__c = true
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        return recentSummaries.isEmpty();
    }

    /**
     * @description Filters a set of account IDs to only those eligible for summary generation
     * @param accountIds Set of Account IDs to check
     * @return Set<Id> Filtered set of account IDs that can have summaries generated
     */
    public static Set<Id> filterEligibleAccounts(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return new Set<Id>();
        }

        DateTime cutoffTime = DateTime.now().addHours(-COOLDOWN_HOURS);

        // Find accounts that have had summaries created recently
        List<AggregateResult> recentSummaries = [
            SELECT Account__c
            FROM Account_Summary__c
            WHERE Account__c IN :accountIds
            AND CreatedDate >= :cutoffTime
            AND Created_By_Agentforce__c = true
            GROUP BY Account__c
        ];

        Set<Id> accountsWithRecentSummaries = new Set<Id>();
        for (AggregateResult ar : recentSummaries) {
            accountsWithRecentSummaries.add((Id)ar.get('Account__c'));
        }

        // Return only accounts without recent summaries
        Set<Id> eligibleAccounts = new Set<Id>();
        for (Id accountId : accountIds) {
            if (!accountsWithRecentSummaries.contains(accountId)) {
                eligibleAccounts.add(accountId);
            }
        }

        return eligibleAccounts;
    }

    /**
     * @description Gets the time remaining until next summary can be generated
     * @param accountId The Account ID to check
     * @return Integer Minutes remaining in cooldown period, or 0 if eligible
     */
    public static Integer getMinutesUntilNextSummary(Id accountId) {
        if (accountId == null) {
            return 0;
        }

        DateTime cutoffTime = DateTime.now().addHours(-COOLDOWN_HOURS);

        List<Account_Summary__c> recentSummaries = [
            SELECT Id, CreatedDate
            FROM Account_Summary__c
            WHERE Account__c = :accountId
            AND CreatedDate >= :cutoffTime
            AND Created_By_Agentforce__c = true
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (recentSummaries.isEmpty()) {
            return 0;
        }

        DateTime nextEligibleTime = recentSummaries[0].CreatedDate.addHours(COOLDOWN_HOURS);
        Long millisUntilEligible = nextEligibleTime.getTime() - DateTime.now().getTime();
        Integer minutesRemaining = (Integer)(millisUntilEligible / (1000 * 60));

        return minutesRemaining > 0 ? minutesRemaining : 0;
    }

    /**
     * @description Checks if a specific summary exists for an account
     * @param accountId The Account ID
     * @param summaryType The type of summary to check for
     * @return Boolean true if summary exists
     */
    public static Boolean summaryExists(Id accountId, String summaryType) {
        if (accountId == null || String.isBlank(summaryType)) {
            return false;
        }

        DateTime cutoffTime = DateTime.now().addHours(-COOLDOWN_HOURS);

        Integer count = [
            SELECT COUNT()
            FROM Account_Summary__c
            WHERE Account__c = :accountId
            AND Summary_Type__c = :summaryType
            AND CreatedDate >= :cutoffTime
            AND Created_By_Agentforce__c = true
        ];

        return count > 0;
    }

    /**
     * @description Gets the most recent summary for an account
     * @param accountId The Account ID
     * @return Account_Summary__c The most recent summary, or null if none exists
     */
    public static Account_Summary__c getMostRecentSummary(Id accountId) {
        if (accountId == null) {
            return null;
        }

        List<Account_Summary__c> summaries = [
            SELECT Id, Name, Summary_Type__c, CreatedDate, Executive_Summary__c,
                   Generation_Status__c, Summary_Generation_Date__c
            FROM Account_Summary__c
            WHERE Account__c = :accountId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        return summaries.isEmpty() ? null : summaries[0];
    }

    /**
     * @description Logs duplicate prevention events for debugging
     * @param accountId The Account ID
     * @param reason Reason why summary was blocked
     */
    public static void logDuplicatePrevention(Id accountId, String reason) {
        System.debug(LoggingLevel.INFO,
            'Account Summary duplicate prevention: AccountId=' + accountId +
            ', Reason=' + reason +
            ', Cooldown=' + COOLDOWN_HOURS + ' hours'
        );
    }
}
