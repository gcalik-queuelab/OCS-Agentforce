@isTest
private class FlowUtilitiesTest {

    @isTest
    static void testValidGetObjectFromId() {
        // Create a test Account record
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Prepare the request
        FlowUtilities.Request req = new FlowUtilities.Request();
        req.actionName = 'get-object-from-id';
        req.recordId = testAccount.Id;

        List<FlowUtilities.Request> requestList = new List<FlowUtilities.Request>{ req };

        // Call the method
        List<FlowUtilities.Result> results = FlowUtilities.processInput(requestList);

        // Assertions
        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].isSuccess);
        System.assertEquals('Account', results[0].actionMessage);
        System.assertEquals('get-object-from-id', results[0].actionName);
    }

    @isTest
    static void testMissingActionName() {
        FlowUtilities.Request req = new FlowUtilities.Request();
        req.actionName = null;
        req.recordId = null;

        List<FlowUtilities.Request> requestList = new List<FlowUtilities.Request>{ req };

        List<FlowUtilities.Result> results = FlowUtilities.processInput(requestList);

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isSuccess);
        System.assertEquals('actionName Not Present.', results[0].errorMessage);
    }

    @isTest
    static void testInvalidActionName() {
        FlowUtilities.Request req = new FlowUtilities.Request();
        req.actionName = 'invalid-action';
        req.recordId = null;

        List<FlowUtilities.Request> requestList = new List<FlowUtilities.Request>{ req };

        List<FlowUtilities.Result> results = FlowUtilities.processInput(requestList);

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isSuccess);
        System.assertEquals('', results[0].errorMessage);
        System.assertEquals('invalid-action', results[0].actionName);
    }
}