public class InvocableWebhookSender {
    public class RequestData {
        @InvocableVariable
        public String endpointUrl;
        
        @InvocableVariable
        public Id recordId;
    }

    @InvocableMethod
    public static List<Integer> sendPostRequest(List<RequestData> requestDataList) {
        List<Integer> responseCodes = new List<Integer>();
        
        for (RequestData requestData : requestDataList) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(requestData.endpointUrl);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody('{"data": "' + requestData.recordId + '"}');
            
            Http http = new Http();
            try {
                HttpResponse res = http.send(req);
                responseCodes.add(res.getStatusCode());
                System.debug('Response: ' + res.getBody());
            } catch (Exception e) {
                System.debug('Error: ' + e.getMessage());
                responseCodes.add(500); // Adding a generic error code
            }
        }
        
        return responseCodes;
    }
}