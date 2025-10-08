@IsTest
private  class QuotePdfService_Test {
    
    

    @IsTest
    static void test() {

        Account acct = new Account(Name = 'Acme Co');
        insert acct;

        Contact con = new Contact(LastName = 'Doe', Email = 'test@example.com', AccountId = acct.Id);
        insert con;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acct.Id,
            Amount = 1000
        );
        insert opp;

        // Minimal Quote. If your org has extra required fields on Quote, set them here.
        Quote q = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Status = 'Draft' // adjust if your org requires a specific status
            // If you reference Quote_Template__c in your service, set something like:
            // Quote_Template__c = 'Standard'
        );
        insert q;

            QuotePdfService.generate(q.Id, true);
    }

}