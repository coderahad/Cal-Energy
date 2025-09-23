global class SyncPaymentsBatch implements Database.Batchable<sObject>,Database.AllowsCallouts,Schedulable
{


    global String jsonString;

    global Database.QueryLocator start(Database.BatchableContext BC)
    {   
        String query = 'SELECT Id from User limit 1';
        
        return Database.getQueryLocator(query);
    }

    global void execute(SchedulableContext SC) {
        Database.executeBatch(new SyncPaymentsBatch(), 1);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {


        
        getpayments();
        

    }
    global void finish(Database.BatchableContext BC) {
        
    }

    public static void getpayments(){
        Datetime nowPST = Datetime.now();


        
        Integer calloutInterval = 60;

        String CompanyId = '1234';
        
        if(!Test.isRunningTest()){

            List<CalEnergy_Settings__mdt> ceSettings = [SELECT Callout_Interval__c, QB_Company_Id_c__c from CalEnergy_Settings__mdt where DeveloperName = 'Org_Settings'];
        

            if(ceSettings.size() > 0){
                calloutInterval = Integer.valueOf(ceSettings[0].Callout_Interval__c);

                CompanyId = ceSettings[0].QB_Company_Id_c__c;
            }

        }

        List<Payment__c> lastPayment = [SELECT QB_Payment_ID__c FROM Payment__c where QB_Payment_ID__c != null order by CreatedDate desc limit 1];

        String lastPaymentId = '0';

        if(lastPayment.size()> 0){

            lastPaymentId = lastPayment[0].QB_Payment_ID__c;
        }


        
        // Format PST datetime in QuickBooks API format (ISO8601)
        String formattedPSTTime = nowPST.addMinutes(calloutInterval*-1).formatGmt('yyyy-MM-dd\'T\'HH:mm:ssXXX');
        
        // Build query string
        String query = 'select * from Payment where MetaData.CreateTime >= \'' + formattedPSTTime + '\' and Id > \''+ lastPaymentId +'\' Order By Id STARTPOSITION 1 MAXRESULTS 400';
        

        try{

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
            }else{
                throw new CalloutException('Sync payment Batch failed : ' + response.getBody());
            }



            if(jsonString != null){
                Map<String, Object> jsonData 				= (Map<String, Object>) JSON.deserializeUntyped(jsonString);
                Map<String, Object> queryResponse 			= (Map<String, Object>) jsonData.get('QueryResponse');
                List<Object> payments 						= (List<Object>) queryResponse.get('Payment');
                List<Payment__c> listQBPaymentToCreate 		= New List<Payment__c>();
                List<String> invoiceIds = new List<String>();
                List<String> paymentIds = new List<String>();

                Map<String, List<Payment__c>> mapToCreatePayments = new Map<String, List<Payment__c>>();
        
                if(payments != null) System.debug(payments.size());
        
                if(payments != null){

                    for(Object paymentObj: payments){
                    
                        
                        Map<String, Object> payment 	= (Map<String, Object>) paymentObj;
                        
                        
                        
                        List<Object> lines = (List<Object>) payment.get('Line');

                        String txnId;
                        
                        // Iterate through the lines
                        for (Object lineObj : lines) {


                            


                            Map<String, Object> line = (Map<String, Object>) lineObj;
                            Decimal amount = (Decimal) line.get('Amount');
                            
                            List<Object> linkedTxns = (List<Object>) line.get('LinkedTxn');
                            
                            // Iterate through linked transactions
                            for (Object linkedTxnObj : linkedTxns) {
                                Map<String, Object> linkedTxn = (Map<String, Object>) linkedTxnObj;
                                
                                String txnType = (String) linkedTxn.get('TxnType');

                                if(txnType == 'Invoice'){
                                    txnId = (String) linkedTxn.get('TxnId');
                                    invoiceIds.add(txnId);

                                    break;


                                }




                                
                                
                                
                            }

                            if(txnId != null){

                            }


                            Map<String, Object> customerRef = (Map<String, Object>) payment.get('CustomerRef');
                            String customerValue 			= (String) customerRef.get('value');
                            String customerName 			= (String) customerRef.get('name');
                            
                            
                            Payment__c qbPaymentToCreate 	= new  Payment__c();
                            
                            Decimal totalAmt 		= amount;
                            Decimal unappliedAmt 	= (Decimal) payment.get('UnappliedAmt');
                            Boolean processPayment 	= (Boolean) payment.get('ProcessPayment');
                            String domain 			= (String) payment.get('domain');
                            Boolean sparse 			= (Boolean) payment.get('sparse');
                            String id 				= (String) payment.get('Id');
                            String syncToken 		= (String) payment.get('SyncToken');
                            
                            Map<String, Object> metaData 	= (Map<String, Object>) payment.get('MetaData');
                            String createTime 				= (String) metaData.get('CreateTime');
                            String lastUpdatedTime 			= (String) metaData.get('LastUpdatedTime');
                            String txnDate 					= (String) payment.get('TxnDate');
                            
                            Map<String, Object> currencyRef = (Map<String, Object>) payment.get('CurrencyRef');
                            String currencyValue 			= (String) currencyRef.get('value');
                            String currencyName 			= (String) currencyRef.get('name');

                            qbPaymentToCreate.Customer_Name__c 		= customerName;
                            qbPaymentToCreate.Customer_Value__c 	= customerValue;
                            qbPaymentToCreate.Currency_Name__c 		= currencyName;
                            qbPaymentToCreate.Currency_Value__c 	= currencyValue;
                            qbPaymentToCreate.Sync_Token__c 		= syncToken;
                            qbPaymentToCreate.QB_Payment_ID__c 		= (String)id;
                            // qbPaymentToCreate.Invoice__c 		    = inv[0].Id; 
                            qbPaymentToCreate.Process_Payment__c 	= processPayment;
                            qbPaymentToCreate.Unapplied_Amount__c 	= unappliedAmt;
                            qbPaymentToCreate.Total_Amount__c 		= (Double)totalAmt;
                            //qbPaymentToCreate.Deposit_Value__c 		= (Double)depositValue;
                
                            // Log the details
                            System.debug('Customer Value: ' + customerValue);
                            System.debug('Customer Name: ' + customerName);
                            System.debug('Total Amount: ' + totalAmt);
                            System.debug('Unapplied Amount: ' + unappliedAmt);
                            System.debug('Process Payment: ' + processPayment);
                            System.debug('Domain: ' + domain);
                            System.debug('Sparse: ' + sparse);
                            System.debug('Id: ' + id);
                            System.debug('Sync Token: ' + syncToken);
                            System.debug('Create Time: ' + createTime);
                            System.debug('Last Updated Time: ' + lastUpdatedTime);
                            System.debug('Transaction Date: ' + txnDate);
                            System.debug('Currency Value: ' + currencyValue);
                            System.debug('Currency Name: ' + currencyName);
                            
                            // listQBPaymentToCreate.add(qbPaymentToCreate);

                            List<Payment__c> toCreatePaymentsList = new List<Payment__c>();

                            if(mapToCreatePayments.containsKey(txnId)){
                                toCreatePaymentsList = mapToCreatePayments.get(txnId);
                            }

                            toCreatePaymentsList.add(qbPaymentToCreate);

                            mapToCreatePayments.put(txnId, toCreatePaymentsList);

                            paymentIds.add((String)id);
                            
                        }

                    }


                    List<Invoice__c> invs = [select Id, Invoice_ID__c from Invoice__c where Invoice_ID__c in :invoiceIds];

                    List<Payment__c> paysAll = [select Id, QB_Payment_ID__c from Payment__c where QB_Payment_ID__c in :paymentIds];

                    Map<String, String> invMap = new Map<String, String>();

                    for(Invoice__c inv1 : invs){

                        invMap.put(inv1.Invoice_ID__c, inv1.Id);

                    }


                    List<String>payIds = new List<String>();


                    for(Payment__c pay : paysAll){

                        payIds.add(pay.QB_Payment_ID__c);

                    }

                    for(String key : mapToCreatePayments.keySet()){

                        if(invMap.containsKey(key)){

                            String InvoiceSfId = invMap.get(key);

                            List<Payment__c> paymentsAllToCreate = mapToCreatePayments.get(key);

                            if(paymentsAllToCreate != null && paymentsAllToCreate.size() > 0){
        
                                for(Payment__c p1 : paymentsAllToCreate){
        
                                    if(payIds.contains(p1.QB_Payment_ID__c) == false){
        
                                        p1.Invoice__c = InvoiceSfId; 

                                        listQBPaymentToCreate.add(p1);
        
                                    }
        
                                }
        
                            }

                        }

                    }

                    System.debug(listQBPaymentToCreate.size());

                    if(!listQBPaymentToCreate.isEmpty()){
                        insert listQBPaymentToCreate;
                    }
        
                }
            }
        }catch (Exception ex) {
            sendErrorEmail.send(ex);
        }
    

        
        
    }
}