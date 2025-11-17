/**
 * @description Trigger for Lead object to generate Account Summaries on conversion/status changes
 * @author Agentforce POC
 * @date 2025
 */
trigger AF_LeadTrigger on Lead (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        AF_LeadTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}
