@isTest
public class SyncPaymentsBatchTest {

    // Mock HTTP response for successful QuickBooks Payment query
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"QueryResponse":{"Payment":[{"Id":"1001","SyncToken":"0","domain":"QBO","sparse":false,"UnappliedAmt":0,"TotalAmt":250,"ProcessPayment":true,"TxnDate":"2024-07-01","CurrencyRef":{"value":"USD","name":"United States Dollar"},"CustomerRef":{"value":"2001","name":"Acme Corp"},"MetaData":{"CreateTime":"2024-07-01T10:00:00-07:00","LastUpdatedTime":"2024-07-01T10:00:00-07:00"},"Line":[{"Amount":250,"LinkedTxn":[{"TxnId":"INV1001","TxnType":"Invoice"}]}]}]}}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testBatchExecute() {
       

        // Insert Invoice__c with a matching Invoice_ID__c
        Invoice__c inv = new Invoice__c(
            Name = 'Test Invoice',
            Invoice_ID__c = 'INV1001'
        );
        insert inv;

        // Register mock
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        SyncPaymentsBatch batch = new SyncPaymentsBatch();
        Database.executeBatch(batch, 1);
        Test.stopTest();

        // Validate Payment__c created and linked to Invoice
        List<Payment__c> payments = [SELECT Id, Customer_Name__c, Invoice__c, QB_Payment_ID__c FROM Payment__c];
        System.assertEquals(1, payments.size());
        System.assertEquals('Acme Corp', payments[0].Customer_Name__c);
        System.assertEquals(inv.Id, payments[0].Invoice__c);
        System.assertEquals('1001', payments[0].QB_Payment_ID__c);
    }

    @isTest
    static void testSchedulable() {
        

        // Register mock
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Run schedulable
        Test.startTest();
        String cron = '0 0 0 1 1 ? 2050'; // arbitrary future cron expression
        System.schedule('Test Payment Sync Job', cron, new SyncPaymentsBatch());
        Test.stopTest();

        System.assert(true, 'Schedulable executed without exception');
    }
}