/**
 * @description Trigger for Account object to generate summaries on Type changes
 * @author Agentforce POC
 * @date 2025
 */
trigger AF_AccountTrigger on Account (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        AF_AccountTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}
