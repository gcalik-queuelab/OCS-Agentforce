/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Website_VisitTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Website_VisitTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Website_Visit__c());
    }
}