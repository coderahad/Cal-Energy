public class inv_ProductTriggerHandler {
    public static Boolean disableTrigger = false;


    public static void handleAfterTrigger(List<Product2> listNew, Map<Id, Product2> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete) {

        
        CalEnergy_Settings__mdt ceSettings = [SELECT QB_Company_Id_c__c, Disable_Trigger__c from CalEnergy_Settings__mdt where DeveloperName = 'Org_Settings' Limit 1];
        

        if(ceSettings.Disable_Trigger__c != TRUE){

            for(Product2 prod : listNew){

           

                if((isInsert || isUpdate) && (prod.QuickBook_Item_ID__c == '' || prod.QuickBook_Item_ID__c == null)){
                    createItemCallout.createItem(prod.Id, ceSettings.QB_Company_Id_c__c);
                }

                

            }

        }
        
        

    }

   
}