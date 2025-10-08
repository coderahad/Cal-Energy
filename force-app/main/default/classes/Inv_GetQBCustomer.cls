public with sharing class Inv_GetQBCustomer {
    


    public static string getOrCreateCostomer(String accId, String companyId){

        List<Account> accs = [SELECT Id,Quickbook_Customer_ID_c__c,  
        Name,Billing_Email__c,QB_Sync_Error_Details__c, QB_Sync_Status_Code__c,  
        BillingStreet, BillingCity, BillingPostalCode, BillingState, BillingCountry 
        FROM Account 
        WHERE Id = :accId];


        Account acc;
        if(accs.size() == 1){
            acc = accs[0];
        }

        if(acc == null){
            return '';
        }
        

        if(acc != null && acc.Quickbook_Customer_ID_c__c == null){

            String query = 'select * from Customer where FullyQualifiedName = \''+acc.Name+'\'';


            Http httpPayments = new Http();
            HttpRequest request = new HttpRequest();
            String encoded = EncodingUtil.urlEncode(query, 'UTF-8');
            request.setEndpoint('callout:QuickBookCallouts/v3/company/'+CompanyId+'/query?query='+encoded);    

            request.setMethod('GET');
            request.setHeader('Accept', 'application/json');
            request.setHeader('Content-Type', 'application/json');
            
            HttpResponse response = new HttpResponse();
            
            response = httpPayments.send(request);

            String jsonString;
            
            if(response.getStatusCode() == 200) {
                // system.debug('response.getStatusCode()'+response.getStatusCode());
                // system.debug('response.getBody() '+response.getBody());
                // return;
                jsonString = response.getBody();

                if(jsonString != null){
                    Map<String, Object> jsonData 				= (Map<String, Object>) JSON.deserializeUntyped(jsonString);
                    Map<String, Object> queryResponse 			= (Map<String, Object>) jsonData.get('QueryResponse');
                    List<Object> customers 						= (List<Object>) queryResponse.get('Customer');
                    
                

                    
                    if(customers != null) System.debug(customers.size());
            
                    if(customers != null && customers.size() > 0){

                        
                        
                            
                        Map<String, Object> customer 	= (Map<String, Object>) customers[0];
                        
                        
                        
                        
                        acc.Quickbook_Customer_ID_c__c = (String)customer.get('Id');


                        // update acc;

                        return (String)customer.get('Id');
                    }else{

                        String email = acc.Billing_Email__c == null ? '' :  acc.Billing_Email__c;
                        String name = acc.Name == null ? '' :  acc.Name;
                        String State = acc.BillingState == null ? '' :  acc.BillingState;
                        String Country = acc.BillingCountry == null ? '' :  acc.BillingCountry;
                        String Street = acc.BillingStreet == null ? '' :  acc.BillingStreet;
                        String PostalCode = acc.BillingPostalCode == null ? '' :  acc.BillingPostalCode;
                        String City = acc.BillingCity == null ? '' :  acc.BillingCity;

                        String body = '{"FullyQualifiedName":"'+name+'","DisplayName":"'+name+'","PrimaryEmailAddr":{"Address":"'+email+'"},"BillAddr":{"CountrySubDivisionCode":"'+State+'","City":"'+City+'","PostalCode":"'+PostalCode+'","Line1":"'+Street+'","Country":"'+Country+'"}}';
                    
                        System.debug(body);



                    

                        HttpRequest request1 = new HttpRequest();
                        request1.setEndpoint('callout:QuickBookCallouts/v3/company/'+CompanyId+'/customer');
                        request1.setHeader('Content-Type', 'application/json');
                        request1.setHeader('Accept' , 'application/json');
                        request1.setMethod('POST');
                        request1.setBody(body);
                        Http http = new Http();
                        HttpResponse cusResponse = new HttpResponse();
                        Integer responseCode;
                        
                        try {
                            cusResponse = http.send(request1);
                            responseCode = response.getStatusCode();
                        }catch (Exception ex) {
                            acc.QB_Sync_Status_Code__c = String.valueOf(responseCode);
                            acc.QB_Sync_Error_Details__c = cusResponse.getBody();
                            
                            // update acc;
                            return '';
                        }
                        system.debug('>>>>response statuscode'+cusResponse.getStatusCode());
                        system.debug('>>>>response body'+cusResponse.getBody());
                        
                        if(responseCode == 200){
                            String res = cusResponse.getBody();


                            
                            Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(res);
                            
                            System.debug(m.keySet());
                            
                            Map<String, Object> customerData = (Map<String, Object>)m.get('Customer');
                            
                            System.debug('>>>>Customer ID : ' + (String)customerData.get('Id'));
                            
                            acc.Quickbook_Customer_ID_c__c = (String)customerData.get('Id');

                            acc.QB_Sync_Status_Code__c = String.valueOf(responseCode);
                            acc.QB_Sync_Error_Details__c = '';

                            // update acc;

                            return (String)customerData.get('Id');

                        }else{
                            acc.QB_Sync_Status_Code__c = String.valueOf(responseCode);
                            acc.QB_Sync_Error_Details__c = cusResponse.getBody();
                            
                            // update acc;

                            return '';
                        }
                    }
                }else{
                    return '';
                }
            }else{
                System.debug('Customer Fetch Error');
                return '';
            }
        }else{
            return acc.Quickbook_Customer_ID_c__c;
        }
    }
}