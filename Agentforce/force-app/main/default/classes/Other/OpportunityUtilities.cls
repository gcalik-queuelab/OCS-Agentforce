/*******************************************************************************************
* @Name         OpportunityUtilities
* @Author       Jake Lankester <jake.lankester@globant.com>
* @Date         31/05/2023
* @Description  Class to store utility methods for the Opportunity Object
*******************************************************************************************/
/* MODIFICATION LOG
* Version          Author       Date               Description
*-------------------------------------------------------------------------------------------
*  1.0             Jake L      	25/08/2023         Initial Creation                                                      
*******************************************************************************************/
public with sharing class OpportunityUtilities {

    public static String processServiceSummary(List<OpportunityLineItem> oppLineItems){
        Set<String> productFamilies = new Set<String>();

        for(OpportunityLineItem oppLineItem : oppLineItems){
            productFamilies.add(oppLineItem.Product_Family__c);
        }
        return String.join(new List<String>(productFamilies), ';');
    }
   
}