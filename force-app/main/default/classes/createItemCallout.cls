public class createItemCallout {
    @future(callout=true)
    public static void createItem(String productId, String CompanyId){


        inv_ProductTriggerHandler.disableTrigger = true;

        List<Product2> products = [select Id, Name, QuickBook_Item_ID__c,QB_Sync_Status_Code__c, QB_Sync_Error_Details__c, Description from Product2 where Id = :productId];


        if(products.size() == 1 && products[0].QuickBook_Item_ID__c == null ){

            Product2 product = products[0];

            String sku = product.Name.replaceAll(' ', '-');

            String body = '{"Name":"' + product.Name + '","Type":"Service","Sku":"' + sku + '","IncomeAccountRef":{"name":"Sales of Product Income","value":"79"},"ExpenseAccountRef":{"name":"Cost of Goods Sold","value":"80"}}';


            HttpRequest request1 = new HttpRequest();
            Http http = new Http();
            request1.setEndpoint('callout:QuickBookCallouts/v3/company/'+CompanyId+'/item?minorversion=73');
            request1.setHeader('Content-Type', 'application/json');
            request1.setHeader('Accept' , 'application/json');
            request1.setMethod('POST');
            request1.setBody(body);
            
            HttpResponse response = new HttpResponse();
            Integer responseCode;
            try{
                response = http.send(request1);
                responseCode = response.getStatusCode();
            }catch (Exception ex) {
                product.QB_Sync_Status_Code__c = String.valueOf(responseCode);
                product.QB_Sync_Error_Details__c = response.getBody();
                
                update product;
            }
            system.debug('>>>>response statuscode'+response.getStatusCode());
            system.debug('>>>>response body'+response.getBody());
            
            
            

            if(responseCode == 200){
                String res = response.getBody();
                
                Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(res);
                
                System.debug(m.keySet());
                
                Map<String, Object> itemData = (Map<String, Object>)m.get('Item');
                
                System.debug('>>>>Item ID : ' + (String)itemData.get('Id'));
                System.debug('>>>>Item ID : ' + (String)itemData.get('SyncToken'));
                
                


                product.QuickBook_Item_ID__c = (String)itemData.get('Id');
                // product.QB_SyncToken__c = (String)itemData.get('SyncToken');
                update product;
            }else{

                product.QB_Sync_Status_Code__c = String.valueOf(responseCode);
                product.QB_Sync_Error_Details__c = response.getBody();
                
                update product;

            }
        }else{

            System.debug('Product Not Found');

        }
    }

}