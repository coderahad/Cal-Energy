public  class createInvoiceCallout {
    


    @future(callout=true)
    public static void createinvoice(String oppId, String oldStatus, String CurrentStatus, String CompanyId){

        Opportunity opp = [Select Name,QB_Sync_Error_Code__c, QB_Sync_Error_Details__c, QuickBook_Invoice_Id__c, CloseDate, Amount, Account.Id, Account.Name, Account.Quickbook_Customer_ID_c__c,Account.Billing_Email__c, (Select Id, Product2Id, Product2.Name, Product2.QuickBook_Item_ID__c, Quantity, UnitPrice, TotalPrice from OpportunityLineItems), Id, StageName from Opportunity where Id = : oppId];

         if(opp.QuickBook_invoice_Id__c != null && opp.QuickBook_invoice_Id__c != ''){

            System.debug('There is already an invoice created for this quote');
            return;
        }

        if(oldStatus == CurrentStatus){

            System.debug('Stage Not Changed');
            return;
        }

        
       


        if(opp.Account.Quickbook_Customer_ID_c__c == null || opp.Account.Quickbook_Customer_ID_c__c == ''){
            System.debug('This Account Is not having reference');
            return;
        }

        
        String lineJSON = '';

        List<OpportunityLineItem> lineItems = opp.OpportunityLineItems;

        Integer size = lineItems.size();


        Integer i = 1;

        for(OpportunityLineItem item : lineItems ){

            Decimal UnitPrice = item.UnitPrice;
            Decimal TotalPrice = UnitPrice * item.Quantity;

            lineJSON += '{"DetailType":"SalesItemLineDetail","Amount":'+ TotalPrice +', "SalesItemLineDetail":{"UnitPrice":'+ UnitPrice +', "Qty":'+ item.Quantity +',"ItemRef":{"name":"' + item.Product2.Name + '","value":"' + item.Product2.QuickBook_Item_ID__c + '"}}}';
            if(i < size){
                lineJSON += ',';
            }
            i++;
        }

        // lineJSON = '{"DetailType":"SalesItemLineDetail","Amount":'+ quote.Amount +', "SalesItemLineDetail":{"UnitPrice":'+ quote.Amount +', "Qty":1 ,"ItemRef":{"name":"Salesforce Invoice Item","value":"19"}}}';

        String formattedDate = opp.CloseDate.year()+'-'+opp.CloseDate.month()+'-'+opp.CloseDate.day();


        String body;

        if(opp.Account.Billing_Email__c != null){
            body = '{"BillEmail" : {"Address":"'+opp.Account.Billing_Email__c+'"},"DueDate" : "' + formattedDate + '","Line":[' + lineJSON + '],"CustomerRef":{"value":"'+ opp.Account.Quickbook_Customer_ID_c__c +'"}}';
        }else{
            body = '{"DueDate" : "' + formattedDate + '","Line":[' + lineJSON + '],"CustomerRef":{"value":"'+ opp.Account.Quickbook_Customer_ID_c__c +'"}}';
        
        }
        Http http = new Http();

        System.debug(body);

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
        }
    }     
}