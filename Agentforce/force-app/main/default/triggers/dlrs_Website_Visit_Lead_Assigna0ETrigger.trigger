/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_Website_Visit_Lead_Assigna0ETrigger on Website_Visit_Lead_Assignment__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(Website_Visit_Lead_Assignment__c.SObjectType);
}