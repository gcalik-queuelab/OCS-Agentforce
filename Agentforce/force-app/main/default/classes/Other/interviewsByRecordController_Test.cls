@IsTest
    private class interviewsByRecordController_Test {
        @IsTest
        static void testBehavior() {
            Account acct = new Account(Name = 'Test Account');
            insert acct;
            Test.startTest();
            System.assertNotEquals(null, interviewsByRecordController.getInterviews(acct.Id));
            System.assertEquals(null, interviewsByRecordController.deleteInterview(acct.Id));
            Test.stopTest();
        }
    }