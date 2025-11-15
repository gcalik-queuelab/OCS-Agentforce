@isTest
public class InvocableWebhookSenderTest {
    @isTest
    static void testSendPostRequest() {
        // Create test data
        String testEndpointUrl = 'https://prod-189.westeurope.logic.azure.com:443/workflows/5416132961274b7ea1d12e206fbf5e38/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=ZIyFx_RRD34ufmPpOf3qIaSszSNEBmd1X45H2U4iRD0';
        Id testRecordId = '001000000000001';

        // Create a list of RequestData
        List<InvocableWebhookSender.RequestData> requestDataList = new List<InvocableWebhookSender.RequestData>();
        InvocableWebhookSender.RequestData requestData = new InvocableWebhookSender.RequestData();
        requestData.endpointUrl = testEndpointUrl;
        requestData.recordId = testRecordId;
        requestDataList.add(requestData);

        // Set up the mock response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Call the method
        Test.startTest();
        List<Integer> responseCodes = InvocableWebhookSender.sendPostRequest(requestDataList);
        Test.stopTest();

        // Verify the response
        System.assertEquals(1, responseCodes.size());
        System.assertEquals(200, responseCodes[0]); // Assuming the mock returns 200 OK
    }

    // Mock class to simulate HTTP response
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"message": "Success"}');
            res.setStatusCode(200);
            return res;
        }
    }
}