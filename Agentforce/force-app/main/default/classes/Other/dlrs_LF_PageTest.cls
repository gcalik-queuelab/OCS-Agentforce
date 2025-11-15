/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_LF_PageTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_LF_PageTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new LF__Page__c());
    }
}