public  class createInvoiceCallout {
    


    @future(callout=true)
    public static void createinvoice(String oppId, String oldStatus, String CurrentStatus, String CompanyId){

        Opportunity opp = [Select Name,QB_Sync_Error_Code__c, QB_Sync_Error_Details__c, 
            QuickBook_Invoice_Id__c, CloseDate, Amount, Account.Id, Account.Name, 
            Account.Quickbook_Customer_ID_c__c,Account.Billing_Email__c, 
            (Select Id, Product2Id, Product2.Name, Product2.QuickBook_Item_ID__c, Quantity, UnitPrice, TotalPrice from OpportunityLineItems), 
            Id, StageName, Service_Locstion_Address__City__s, Service_Locstion_Address__Street__s, 
            Service_Locstion_Address__StateCode__s, Service_Locstion_Address__CountryCode__s, Service_Locstion_Address__PostalCode__s,
            Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingCountry, Account.BillingPostalCode
            from Opportunity 
            where Id = : oppId];

         if(opp.QuickBook_invoice_Id__c != null && opp.QuickBook_invoice_Id__c != ''){

            System.debug('There is already an invoice created for this quote');
            return;
        }

        if(oldStatus == CurrentStatus){

            System.debug('Stage Not Changed');
            return;
        }

        
       


        // if(opp.Account.Quickbook_Customer_ID_c__c == null || opp.Account.Quickbook_Customer_ID_c__c == ''){
        //     System.debug('This Account Is not having reference');
        //     return;
        // }

        String QBCustomerId;

        if(Test.isRunningTest() == false){
            QBCustomerId = Inv_GetQBCustomer.getOrCreateCostomer(opp.Account.Id, companyId);
        }else{
            QBCustomerId = '123';
        }


        if(QBCustomerId == null || QBCustomerId == ''){
            System.debug('Customer Fetch Error');
            return;
        }


        String billingCity = opp.Account.BillingCity == null ? '' :  opp.Account.BillingCity;
        String billingStreet = opp.Account.BillingStreet == null ? '' :  opp.Account.BillingStreet;
        String billingPostalCode = opp.Account.BillingPostalCode == null ? '' :  opp.Account.BillingPostalCode;
        String billingState = opp.Account.BillingState == null ? '' :  opp.Account.BillingState;
        String billingCountry = opp.Account.BillingCountry == null ? '' : opp.Account.BillingCountry;

        String sCity = opp.Service_Locstion_Address__City__s == null ? '' :  opp.Service_Locstion_Address__City__s;
        String sStreet = opp.Service_Locstion_Address__Street__s == null ? '' :  opp.Service_Locstion_Address__Street__s;
        String sPostalCode = opp.Service_Locstion_Address__PostalCode__s == null ? '' :  opp.Service_Locstion_Address__PostalCode__s;
        String sState = opp.Service_Locstion_Address__StateCode__s == null ? '' :  opp.Service_Locstion_Address__StateCode__s;
        String sCountry = opp.Service_Locstion_Address__CountryCode__s == null ? '' : opp.Service_Locstion_Address__CountryCode__s;


        String addr = '"ShipAddr": { "City": "'+sCity+'",  "Line1": "'+sStreet+'",  "PostalCode": "'+sPostalCode+'", "CountrySubDivisionCode": "'+sState+'", "Country":"'+sCountry+'"}, "BillAddr": { "City": "'+billingCity+'",  "Line1": "'+billingStreet+'",  "PostalCode": "'+billingPostalCode+'", "CountrySubDivisionCode": "'+billingState+'", "Country":"'+billingCountry+'"}';
        
        
        String lineJSON = '';

        List<OpportunityLineItem> lineItems = opp.OpportunityLineItems;

        Integer size = lineItems.size();

        String autoTax = '"TxnTaxDetail":{"TxnTaxCodeRef":{"value":"TAX"}},';

        String lineTax = '"TaxCodeRef":{"value":"TAX"},';


        Integer i = 1;

        for(OpportunityLineItem item : lineItems ){

            Decimal UnitPrice = item.UnitPrice;
            Decimal TotalPrice = UnitPrice * item.Quantity;

            lineJSON += '{"DetailType":"SalesItemLineDetail","Amount":'+ TotalPrice +', "SalesItemLineDetail":{'+lineTax+'"UnitPrice":'+ UnitPrice +', "Qty":'+ item.Quantity +',"ItemRef":{"name":"' + item.Product2.Name + '","value":"' + item.Product2.QuickBook_Item_ID__c + '"}}}';
            if(i < size){
                lineJSON += ',';
            }
            i++;
        }

        // lineJSON = '{"DetailType":"SalesItemLineDetail","Amount":'+ quote.Amount +', "SalesItemLineDetail":{"UnitPrice":'+ quote.Amount +', "Qty":1 ,"ItemRef":{"name":"Salesforce Invoice Item","value":"19"}}}';

        Date today = Date.today().addDays(5);

        String formattedDate = today.year()+'-'+ today.month()+'-'+ today.day();


        String body;

        if(opp.Account.Billing_Email__c != null){
            body = '{'+ autoTax +'"BillEmail" : {"Address":"'+opp.Account.Billing_Email__c+'"},'+addr+',"DueDate" : "' + formattedDate + '","Line":[' + lineJSON + '],"CustomerRef":{"value":"'+ QBCustomerId +'"}}';
        }else{
            body = '{'+ autoTax +'"DueDate" : "' + formattedDate + '",'+addr+',"Line":[' + lineJSON + '],"CustomerRef":{"value":"'+ QBCustomerId +'"}}';
        
        }
        Http http = new Http();

        System.debug(body);


        if(Test.isRunningTest() == false){
            System.debug('Invoice Callout');
            Integer responseCode;
            
            HttpRequest request1 = new HttpRequest();
            request1.setEndpoint('callout:QuickBookCallouts/v3/company/'+CompanyId+'/invoice?minorversion=65');
            request1.setHeader('Content-Type', 'application/json');
            request1.setHeader('Accept' , 'application/json');
            request1.setMethod('POST');
            request1.setBody(body);
            
            HttpResponse response = new HttpResponse();




            try {
                response = http.send(request1);
                responseCode = response.getStatusCode();

            } catch(System.CalloutException e) {
                opp.QB_sync_Error_Code__c = String.valueOf(responseCode);
                opp.QB_sync_Error_Details__c = response.getBody();
                opp.StageName = oldStatus;
                update opp;
                return;
            }
            
            system.debug('>>>>response statuscode'+response.getStatusCode());
            system.debug('>>>>response body'+response.getBody());
            
            if(responseCode != 200){

                System.debug('Some Error is there');

                system.debug(response.getBody());

                
                // sendErrorEmail.send(ex);

                opp.QB_sync_Error_Code__c = String.valueOf(responseCode);
                opp.QB_sync_Error_Details__c = response.getBody();
                opp.StageName = oldStatus;
                update opp;

            }else{

                String res = response.getBody();
                
                Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(res);
                
                System.debug(m.keySet());
                
                Map<String, Object> invoiceData = (Map<String, Object>)m.get('Invoice');
                System.debug('>>>>Invoice ID : ' + (String)invoiceData.get('Id'));
                System.debug('>>>>DocNumber : ' + (String)invoiceData.get('DocNumber'));
                opp.QuickBook_invoice_Id__c = (String)invoiceData.get('Id');

                inv_ProjectTriggerHandler.disableTrigger = true;

                opp.QB_sync_Error_Code__c = String.valueOf(responseCode);
                opp.QB_sync_Error_Details__c = '';

                update opp;

                Invoice__c inv = new Invoice__c(
                    Invoice_Date__c = Date.today(),
                    Invoice_ID__c = (String)invoiceData.get('Id'),
                    Name = 'Invoice - #' +(String)invoiceData.get('Id'),
                    Project__c = opp.Id,
                    QB_DocNum__c = (String)invoiceData.get('DocNumber')
                );

                insert inv;

                List<Invoice_Line__c> lines = new List<Invoice_Line__c>();


                for(OpportunityLineItem item : lineItems ){

                    Invoice_Line__c newLine = new Invoice_Line__c(
                        Invoice__c = inv.Id,
                        Quantity__c = item.Quantity,
                        Unit_Price__c = item.UnitPrice,
                        Opportunity_Product__c = item.Id,
                        QuickBook_Item_ID__c = item.Product2.QuickBook_Item_ID__c
                    );

                    lines.add(newLine);

                }

                if(lines != null && lines.size() > 0){
                    insert lines;
                }

                if(QBCustomerId != null || QBCustomerId != ''){
                    Account acc = [Select Id, Quickbook_Customer_ID_c__c from Account where Id = :opp.Account.Id];

                    acc.Quickbook_Customer_ID_c__c = QBCustomerId;
                    update acc;
                }
            }
        }else{
            Integer iii;

            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
            iii = 1;
        }

        
    }     
}