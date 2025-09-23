public with sharing class sendErrorEmail {
    public sendErrorEmail() {

    }

    public static void send(Exception ex) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();


        CalEnergy_Settings__mdt ceSettings = [SELECT Error_Emails__c from CalEnergy_Settings__mdt where DeveloperName = 'Org_Settings' Limit 1];
        



        if(ceSettings.Error_Emails__c != null){
            List<String> emailAddresses = new List<String>();
            emailAddresses.addAll(ceSettings.Error_Emails__c.split(','));

            mail.setToAddresses(emailAddresses);
            mail.setSubject('Salesforce HTTP Callout Error');
            mail.setPlainTextBody('An error occurred during HTTP callout:\n\n' +
                                ex.getMessage() + '\n\n' +
                                ex.getStackTraceString());

            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
        }
    }
}