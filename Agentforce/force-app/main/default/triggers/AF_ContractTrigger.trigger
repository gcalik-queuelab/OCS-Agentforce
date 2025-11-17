/**
 * @description Trigger for Contract__c object to generate Account Summaries on contract changes
 * @author Agentforce POC
 * @date 2025
 */
trigger AF_ContractTrigger on Contract__c (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        AF_ContractTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}
