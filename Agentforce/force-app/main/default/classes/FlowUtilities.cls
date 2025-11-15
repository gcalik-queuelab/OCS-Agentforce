/*******************************************************************************************
* @Name         FlowUtilities
* @Author       Jake Lankester <jake.lankester@globant.com>
* @Date         31/05/2023
* @Description  Utility class to be Invoked by Flows
*******************************************************************************************/
/* MODIFICATION LOG
* Version          Author       Date               Description
*-------------------------------------------------------------------------------------------
*  1.0             Jake L       25/08/2023         Initial Creation 
*  1.1             Jake L       28/09/2023         Add Service Summary for Contracts/Accounts                                                     
*******************************************************************************************/
public without sharing class FlowUtilities {

    @TestVisible private static final String GET_OBJECT_FROM_ID = 'get-object-from-id';

    /*
        Class used to pass inputs to the Invocable action
    */
    public class Request {
        @InvocableVariable(Label='Action Name' Required=true)
        public String actionName;
        @InvocableVariable(Label='Record Id' Required=false)
        public String recordId;
        @InvocableVariable(Label='Record Collection' Required=false)
        public List<sObject> records;
    }

    /*
        Class used to store the outputs of the Invocable action
    */
    public class Result {
        @InvocableVariable(Label='checkbox')
        public Boolean checkbox;
        @InvocableVariable(Label='Message From Action')
        public String actionMessage;
        @InvocableVariable(Label='Success')
        public Boolean isSuccess;
        @InvocableVariable(Label='Error Message')
        public String errorMessage;
        @InvocableVariable(Label='Action Name')
        public String actionName;
    }

    /*
        Processes the request list depending on the provided action name
    */
    @InvocableMethod(Label='Flow Admin Utilities')
    public static List<Result> processInput (List<Request> requestList){

        List<Result> results = new List<Result>();

        for (Request req : requestList) {

            Result result = validateInput(req, new Result());
            result.isSuccess = false;
            if (String.isBlank(result.errorMessage)) { //Add new actions here if required
                if(req.actionName.toLowerCase() == GET_OBJECT_FROM_ID){
                    result = getObjectNameFromRecordId(req, result);
                }
            }
            results.add(result);
        }
        return results;
    }

    /*
        Evaluate our request to confirm that an action name has been provided
    */
    private static Result validateInput (Request request, Result result) {
        Boolean actionNamePresent = String.isNotBlank(request.actionName);
        result.errorMessage = (actionNamePresent ? '' : 'actionName Not Present.');
        result.actionName = request.actionName;
        return result;
    }


    private static Result getObjectNameFromRecordId(Request request, Result result){
        Id recordId = request.recordId;
        String objectNameresult = (String)recordId.getSObjectType().getDescribe().getName();
        if(!String.isBlank(objectNameresult)){
            result.isSuccess = true;
            result.actionMessage = objectNameresult;
        }

        return result;
    }
}