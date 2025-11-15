/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Contract_VariationTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Contract_VariationTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Contract_Variation__c());
    }
}