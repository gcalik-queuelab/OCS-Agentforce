/*******************************************************************************************
* @Name         ContractUtilities
* @Author       Jake Lankester <jake.lankester@globant.com>
* @Date         28/09/2023
* @Description  Class to store utility methods for the Contract Object
*******************************************************************************************/
/* MODIFICATION LOG*
* Version          Author       Date               Description
*-------------------------------------------------------------------------------------------
*  1.0             Jake L      	28/09/2023         Initial Creation                                                      
*******************************************************************************************/
public with sharing class ContractUtilities {
   
  public static String processServiceSummary(List<Contract_Line_Item__c> contractLineItems){
        Set<String> productFamilies = new Set<String>();

        for(Contract_Line_Item__c lineItem : contractLineItems){
            productFamilies.add(lineItem.Product_Family__c);
        }
        return String.join(new List<String>(productFamilies), ';');
    }

}