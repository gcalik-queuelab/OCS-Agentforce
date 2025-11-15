global class DeleteObjectChangeLogsBatch implements Database.Batchable<sObject> {
    private String strPFrom;

    public DeleteObjectChangeLogsBatch(String strFrom) {
        strPFrom = strFrom;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id FROM ' + strPFrom;
        
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<SObject> objList) {
        try {
            delete objList;
         
        } catch(Exception e) {
            System.debug('***AMM: ' + e);
        }
    }    
    global void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }    
}