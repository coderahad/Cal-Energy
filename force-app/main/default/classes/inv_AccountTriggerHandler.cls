public class inv_AccountTriggerHandler {
    

    public static Boolean disableTrigger = false;


    public static void handleAfterTrigger(List<Account> listNew, Map<Id, Account> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete) {

        CalEnergy_Settings__mdt ceSettings = [SELECT QB_Company_Id_c__c, Disable_Trigger__c, Error_Emails__c from CalEnergy_Settings__mdt where DeveloperName = 'Org_Settings' Limit 1];
        

        if(ceSettings.Disable_Trigger__c != TRUE){
            
            
            for(Account acc : listNew){

                if(isInsert && (acc.Quickbook_Customer_ID_c__c == '' || acc.Quickbook_Customer_ID_c__c == null)){
                    createCustomerCallout.createCustomer(acc.Id, ceSettings.QB_Company_Id_c__c);
                }
            }
        }
        
        

    }
}