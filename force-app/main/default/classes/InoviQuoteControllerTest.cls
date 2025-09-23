@isTest
private class InoviQuoteControllerTest {
    
    private static Quote setupTestData() {
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = acc.Id
        );
        insert opp;

        // Create Pricebook
        Pricebook2 pb = new Pricebook2(Name = 'Test Pricebook', IsActive = true);
        insert pb;

        // Create Product
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        // Create PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        // Create Quote
        Quote q = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            Status = 'Draft'
        );
        insert q;

        // Create QuoteLineItem
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 2,
            UnitPrice = 100
        );
        insert qli;

        return q;
    }
    
    @isTest
    static void testGetQuoteDetails() {
        Quote testQuote = setupTestData();
        
        Test.startTest();
        Map<String, Object> result = InoviQuoteController.getQuoteDetails(testQuote.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('quote'), 'Result should contain quote key');
        System.assert(result.containsKey('quoteLines'), 'Result should contain quoteLines key');
    }
    
    @isTest
    static void testUpdateQuoteStatus() {
        Quote testQuote = setupTestData();
        
        Test.startTest();
        String result = InoviQuoteController.updateQuoteStatus(testQuote.Id, 'Accepted', 'PO-12345');
        Test.stopTest();
        
        System.assertEquals('success', result, 'Update should return success');
        
        Quote updatedQuote = [SELECT Status, PO_Number__c FROM Quote WHERE Id = :testQuote.Id];
        System.assertEquals('Accepted', updatedQuote.Status);
        System.assertEquals('PO-12345', updatedQuote.PO_Number__c);
    }
    
    @isTest
    static void testSaveSelectedQuoteLines() {
        Quote testQuote = setupTestData();
        List<QuoteLineItem> qlis = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :testQuote.Id];
        
        Test.startTest();
        InoviQuoteController.saveSelectedQuoteLines(new List<Id>{ qlis[0].Id });
        Test.stopTest();
        
        List<QuoteLineItem> updatedQLIs = [SELECT Id FROM QuoteLineItem WHERE Id = :qlis[0].Id];
        System.assertEquals(1, updatedQLIs.size(), 'QuoteLineItem should still exist after update');
    }
}