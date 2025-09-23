public class inv_ProjectTriggerHandler {

    public static Boolean disableTrigger = false;


    public static void handleAfterTrigger(List<Opportunity> listNew, Map<Id, Opportunity> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete) {

        
        CalEnergy_Settings__mdt ceSettings = [SELECT QB_Company_Id_c__c, Disable_Trigger__c from CalEnergy_Settings__mdt where DeveloperName = 'Org_Settings' Limit 1];
        

        if(ceSettings.Disable_Trigger__c != TRUE){

            for(Opportunity opp : listNew){
                
                if(oldMap.get(opp.Id).StageName != opp.StageName && (opp.StageName == 'Send to Quickbooks' || opp.StageName == 'Closed Won' || opp.StageName == 'Closed Won')){
                    createInvoiceCallout.createInvoice(opp.Id, oldMap.get(opp.Id).StageName, opp.StageName, ceSettings.QB_Company_Id_c__c);

                }
            

            }
        }
        
        

    }
}