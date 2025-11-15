/************************************************************************************************
* @company          Globant
* @author           Anay Karkhanis href=<anay.karkhanis@globant.com>
* @project          OCS
* @name             OCS_PostMigrationScriptBatch
* @description      Batch Process for user object migration 
* @dependencies
* @changes (Version)
* --------   ---   ----------   ---------------------------   -----------------------------------
*            No.   Date         Author                        Description
* --------   ---   ----------   ---------------------------   -----------------------------------
* @version   1.0   2024-01-22   Anay K                        Initial version.
************************************************************************************************/

/**
* @method       OCS_PostMigrationScriptBatch
* @description  Batch Process for post migration record processing. 
                The purpose of the batch is to update the field on the object thereby triggering the record flows.
                The Migration_Flows_Enabled__c field on OCS_Config_Settings_CSH__c will ensure that the create path
                of the record flows are being executed on updating the fields in the batch.
* @author       Anay K - 2024-01-22
*/
global class OCS_PostMigrationScriptBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    public String objectName;
    public String fieldToUpdateName;
    public String queryWhereClause;
    
    public OCS_PostMigrationScriptBatch(String objectName, String fieldToUpdateName, String queryWhereClause) {
        this.objectName = objectName;
        this.fieldToUpdateName = fieldToUpdateName;
        this.queryWhereClause = queryWhereClause;
    }
    

    global Database.QueryLocator start(Database.BatchableContext objBatchableContext) {
        System.debug('\n\n-=#=-   ' + 'MigrationBatch - start' +
        '\n-=#=-   ' + 'objBatchableContext' + ': ' + objBatchableContext + '\n');
        
        String query = 'Select Id,' + fieldToUpdateName + ' from ' + objectName + ' where ' + queryWhereClause;
        
        System.debug('\n\n-=#=-   '+query);
               
        return Database.getQueryLocator (query);            
        
    }

    global void execute(Database.BatchableContext objBatchableContext, List<SObject> lstObjects) {
        System.debug('\n\n-=#=-   ' + 'MigrationBatch - execute' +
                     '\n-=#=-   ' + 'objBatchableContext' + ': ' + objBatchableContext + '\n' + JSON.serializePretty(lstObjects));

        for (Sobject currentObj: lstObjects){
            
            String currentFieldValue = (String)currentObj.get(fieldToUpdateName);
            currentFieldValue = String.isBlank(currentFieldValue) ? '' : currentFieldValue;
            
            if(currentFieldValue.endsWith('*'))
                currentObj.put(fieldToUpdateName,currentFieldValue.removeEnd('*'));
            else
                currentObj.put(fieldToUpdateName,currentFieldValue + '*');

        }
        update lstObjects;

    }

    global void finish(Database.BatchableContext objBatchableContext) {
        System.debug('\n\n-=#=-   ' + 'MigrationBatch - finish' +
                     '\n-=#=-   ' + 'objBatchableContext' + ': ' + objBatchableContext + '\n');

    }    
}