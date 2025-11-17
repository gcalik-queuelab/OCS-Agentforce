/**
 * @description Trigger for Opportunity object to generate Account Summaries
 * @author Agentforce POC
 * @date 2025
 */
trigger AF_OpportunityTrigger on Opportunity (after insert, after update) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            AF_OpportunityTriggerHandler.handleAfterInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            AF_OpportunityTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
