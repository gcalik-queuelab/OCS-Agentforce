/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Opportunity_Stage_HistoryTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Opportunity_Stage_HistoryTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Opportunity_Stage_History__c());
    }
}