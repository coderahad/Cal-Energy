public class createCustomerCallout {

    @future(callout=true)
    public static void createCustomer(String AccountId, String CompanyId){
        String body = '{"FullyQualifiedName":"King Groceries","PrimaryEmailAddr":{"Address":"jdrew@myemail.com"},"DisplayName":"King Groceries","BillAddr":{"CountrySubDivisionCode":"CA","City":"Mountain View","PostalCode":"94042","Line1":"123 Main Street","Country":"USA"}}';

        List<Account> accs = [SELECT Id, Name,Billing_Email__c,QB_Sync_Error_Details__c, QB_Sync_Status_Code__c,  BillingStreet, BillingCity, BillingPostalCode, BillingState, BillingCountry FROM Account WHERE Id = :AccountId];


        if(accs.size() == 1){

            Account acc = accs[0];

            String email = acc.Billing_Email__c == null ? '' :  acc.Billing_Email__c;
            String name = acc.Name == null ? '' :  acc.Name;
            String State = acc.BillingState == null ? '' :  acc.BillingState;
            String Country = acc.BillingCountry == null ? '' :  acc.BillingCountry;
            String Street = acc.BillingStreet == null ? '' :  acc.BillingStreet;
            String PostalCode = acc.BillingPostalCode == null ? '' :  acc.BillingPostalCode;
            String City = acc.BillingCity == null ? '' :  acc.BillingCity;

            body = '{"FullyQualifiedName":"'+name+'","DisplayName":"'+name+'","PrimaryEmailAddr":{"Address":"'+email+'"},"BillAddr":{"CountrySubDivisionCode":"'+State+'","City":"'+City+'","PostalCode":"'+PostalCode+'","Line1":"'+Street+'","Country":"'+Country+'"}}';
        
            System.debug(body);



           

            HttpRequest request1 = new HttpRequest();
            request1.setEndpoint('callout:QuickBookCallouts/v3/company/'+CompanyId+'/customer');
            request1.setHeader('Content-Type', 'application/json');
            request1.setHeader('Accept' , 'application/json');
            request1.setMethod('POST');
            request1.setBody(body);
            Http http = new Http();
            HttpResponse response = new HttpResponse();
            Integer responseCode;
            
            try {
                response = http.send(request1);
                responseCode = response.getStatusCode();
            }catch (Exception ex) {
                acc.QB_Sync_Status_Code__c = String.valueOf(responseCode);
                acc.QB_Sync_Error_Details__c = response.getBody();
                
                update acc;
                return;
            }
            system.debug('>>>>response statuscode'+response.getStatusCode());
            system.debug('>>>>response body'+response.getBody());
            
            if(responseCode == 200){
                String res = response.getBody();


                
                Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(res);
                
                System.debug(m.keySet());
                
                Map<String, Object> customerData = (Map<String, Object>)m.get('Customer');
                
                System.debug('>>>>Customer ID : ' + (String)customerData.get('Id'));
                
                acc.Quickbook_Customer_ID_c__c = (String)customerData.get('Id');

                acc.QB_Sync_Status_Code__c = String.valueOf(responseCode);
                acc.QB_Sync_Error_Details__c = '';

                update acc;

            }else{
                acc.QB_Sync_Status_Code__c = String.valueOf(responseCode);
                acc.QB_Sync_Error_Details__c = response.getBody();
                
                update acc;
            }
        }
    }
}