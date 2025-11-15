/************************************************************************************************
* @company          Globant
* @author           Anay Karkhanis href=<anay.karkhanis@globant.com>
* @project          OCS
* @name             OCS_PostMigrationScriptBatchTest
* @description      Test class OCS_PostMigrationScriptBatch batch process 
* @dependencies
* @changes (Version)
* --------   ---   ----------   ---------------------------   -----------------------------------
*            No.   Date         Author                        Description
* --------   ---   ----------   ---------------------------   -----------------------------------
* @version   1.0   2024-01-22   Anay K                        Initial version.
************************************************************************************************/

@isTest
public class OCS_PostMigrationScriptBatchTest {
    
    /**
    * @method       setupTestData
    * @description  setupTestData for Batch Process for object migration 
    * @author       Anay K - 2024-01-22
    */
    @testSetup public static void setupTestData()  {



        OCS_Config_Settings_CSH__c setting = new OCS_Config_Settings_CSH__c();
        setting.Migration_Flows_Enabled__c = false;
        setting.Flows_Disabled__c= true;
        setting.Triggers_Disabled__c= true;
        setting.Validation_Rules_Disabled__c= true;
        insert setting;

        Account objAccount = new Account();
        objAccount.Name ='AccTest';
        objAccount.Legacy_Id__c='Test';
        objAccount.Description = 'Test';
        insert objAccount;

        setting.Migration_Flows_Enabled__c=true;
        update setting;
       
    }    
    
    /**
    * @method       testFieldUpdateForPostMigration
    * @description  Validate the field update which triggers the record flows to execute logic for post migrations
    * @author       Anay K - 2024-01-22
    */
    @isTest static void testFieldUpdateForPostMigration() {  
        Test.startTest();
        Database.executeBatch(new OCS_PostMigrationScriptBatch('Account','Description','Legacy_Id__c != null'), 200);
        Test.stopTest();
        Account objAccount = [Select Id,Description from Account where Name='AccTest' LIMIT 1];
        System.assert(objAccount.Description.endsWith('*'));
    }    
    
    /**
    * @method       testRevertFieldUpdateChangeForPostMigration
    * @description  Validate that the field updated to trigger the record flows in the first batch run
    *               is updated back to it's original value
    * @author       Anay K - 2024-01-22
    */
    @isTest static void testRevertFieldUpdateChangeForPostMigration() {  
        
        Account objAccountToUpdate = [Select Id,Description from Account where Name='AccTest' LIMIT 1];
        objAccountToUpdate.Description +='*' ;
        update objAccountToUpdate;
            
        Test.startTest();
        Database.executeBatch(new OCS_PostMigrationScriptBatch('Account','Description','Legacy_Id__c != null'), 200);
        Test.stopTest();
        Account objAccount = [Select Id,Description from Account where Name='AccTest' LIMIT 1];
        System.assert(!objAccount.Description.endsWith('*'));
        
    }       

}