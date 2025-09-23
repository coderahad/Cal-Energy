@isTest
private class CreateCustomerCallout_Test {


    @isTest
    static void testCreateCustomer_Success() {
       

        // Set Mock Response
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setHeader('Content-Type', 'application/json');
        mockResponse.setBody('{ "Customer": {"Id": "12345","FullyQualifiedName": "King Groceries"}}');
        mockResponse.setStatusCode(200);

        Test.setMock(HttpCalloutMock.class, new CreateCustomerMock(mockResponse));

        Test.startTest();

        Account acc = new Account(
            Name = 'King Groceries',
            Billing_Email__c = 'jdrew@myemail.com',
            BillingStreet = '123 Main Street',
            BillingCity = 'Mountain View',
            BillingPostalCode = '94042',
            BillingState = 'CA',
            BillingCountry = 'USA'
        );
        insert acc;

        createCustomerCallout.createCustomer(acc.Id, 'dev');

        
        Test.stopTest();

        Account updatedAcc = [SELECT Quickbook_Customer_ID_c__c FROM Account Limit 1];
        // System.assertEquals('12345', updatedAcc.Quickbook_Customer_ID_c__c);
    }

    @isTest
    static void testCreateCustomer_Failure() {
        

        // Set Mock Response
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(400);
        mockResponse.setBody('{"Fault": { "Error": [{"Message": "Invalid request"}]}');

        Test.setMock(HttpCalloutMock.class, new CreateCustomerMock(mockResponse));

        Test.startTest();
        Account acc = new Account(
            Name = 'King Groceries',
            Billing_Email__c = 'jdrew@myemail.com',
            BillingStreet = '123 Main Street',
            BillingCity = 'Mountain View',
            BillingPostalCode = '94042',
            BillingState = 'CA',
            BillingCountry = 'USA'
        );
        insert acc;
        
        Test.stopTest();

        createCustomerCallout.createCustomer(acc.Id, 'dev');

        Account testAccount = [SELECT Id, Quickbook_Customer_ID_c__c FROM Account LIMIT 1];
        System.assertEquals(null, testAccount.Quickbook_Customer_ID_c__c);
    }

    private class CreateCustomerMock implements HttpCalloutMock {
        private HttpResponse mockResponse;
        CreateCustomerMock(HttpResponse response) {
            this.mockResponse = response;
        }

        public HttpResponse respond(HttpRequest req) {
            return mockResponse;
        }
    }
}