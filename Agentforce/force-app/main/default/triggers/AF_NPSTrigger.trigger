/**
 * @Name         AF_NPSTrigger
 * @Author       Agentforce Implementation Team
 * @Date         2025-01-15
 * @Description  Trigger on NPS__c object to handle Agentforce AI summary generation
 *               when NPS surveys are marked as "Closed". Delegates all logic to
 *               AF_NPSTriggerHandler for maintainability and testability.
 */
trigger AF_NPSTrigger on NPS__c (after update) {
    AF_NPSTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
}
