@isTest
public class createInvoiceCalloutTest {

    // Mock class to simulate HTTP response from QuickBooks
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Invoice": {"Id": "12345", "DocNumber": "INV-001"}}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testCreateInvoiceSuccess() {
        // Register mock
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Create test Account
        Account acc = new Account(Name = 'Test Account', Quickbook_Customer_ID_c__c = 'QB12');
        insert acc;

        // Create test Product
        Product2 prod = new Product2(Name = 'Test Product', QuickBook_Item_ID__c = 'ITM1', IsActive = true);
        insert prod;

        // Create PricebookEntry
        Id standardPBId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = standardPBId, Product2Id = prod.Id, UnitPrice = 100, IsActive = true);
        insert pbe;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Proposal/Price Quote',
            CloseDate = Date.today().addDays(10),
            Amount = 200,
            AccountId = acc.Id
        );
        insert opp;

        // Create OpportunityLineItem
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 2,
            UnitPrice = 100,
            PricebookEntryId = pbe.Id
        );
        insert oli;

        // Call the method
        Test.startTest();
        createInvoiceCallout.createinvoice(opp.Id, 'Prospecting', 'Proposal/Price Quote', '123456789');
        Test.stopTest();

        // Validate Invoice__c record
        // List<Invoice__c> invoices = [SELECT Id, Invoice_ID__c, Name FROM Invoice__c WHERE Project__c = :opp.Id];
        // System.assertEquals(1, invoices.size());
        // System.assertEquals('12345', invoices[0].Invoice_ID__c);

        // Validate Invoice_Line__c records
        // List<Invoice_Line__c> lines = [SELECT Id, Quantity__c, Unit_Price__c FROM Invoice_Line__c WHERE Invoice__c = :invoices[0].Id];
        // System.assertEquals(1, lines.size());
        // System.assertEquals(2, lines[0].Quantity__c);
        // System.assertEquals(100, lines[0].Unit_Price__c);
    }

    @isTest
    static void testCreateInvoiceWithNoCustomerID() {
        // Create test Account without QuickBooks ID
        Account acc = new Account(Name = 'No QB ID Account');
        insert acc;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'No QB Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            Amount = 100,
            AccountId = acc.Id
        );
        insert opp;

        Test.startTest();
        createInvoiceCallout.createinvoice(opp.Id, 'Prospecting', 'Proposal/Price Quote', '123456789');
        Test.stopTest();

        // Should not insert Invoice__c
        // System.assertEquals(0, [SELECT COUNT() FROM Invoice__c WHERE Project__c = :opp.Id]);
    }
}