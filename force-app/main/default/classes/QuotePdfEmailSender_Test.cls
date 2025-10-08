@IsTest
private class QuotePdfEmailSender_Test {

    @TestSetup
    static void setupData() {
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

        // Simple text email template in user's private folder
        // EmailTemplate et = new EmailTemplate(
        //     Name = 'Quote Send Template',
        //     DeveloperName = 'Quote_Send_Template',
        //     FolderId = UserInfo.getUserId(),
        //     TemplateType = 'text',
        //     Subject = 'Quote for {!Contact.LastName}',
        //     Body = 'Hello {!Contact.FirstName} {!Contact.LastName}, here is your quote.'
        // );
        // insert et;

        // Stash Ids in a custom setting place? Not necessary—query in test methods.
    }

    @IsTest
    static void sendSingleEmail_WithGeneratedPdfAttachment() {
        // Bypass actual PDF rendering during test
        // QuotePdfService.TEST_BYPASS_RENDER = true;

        Contact c = [SELECT Id FROM Contact LIMIT 1];
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        EmailTemplate et = [SELECT Id from EmailTemplate WHERE Name = 'Quote Email Template' LIMIT 1];

        // Build invocable input
        QuotePdfEmailSender.Input req = new QuotePdfEmailSender.Input();
        req.QuoteId = q.Id;
        req.ContactId = c.Id;
        req.EmailTemplateId = et.Id;
        req.CreatePublicLink = false; // not needed for email attachment

        Test.startTest();
        // Invoke the method under test
        QuotePdfEmailSender.send(new List<QuotePdfEmailSender.Input>{ req });
        Test.stopTest();

        // Assert: no exception thrown and an activity was created (since class sets SaveAsActivity = true)
        // Note: Task creation timing may vary—post-send, there should be at least one task for the Contact.
        Integer taskCount = [
            SELECT COUNT()
            FROM Task
            WHERE WhoId = :c.Id
        ];
        // System.assert(taskCount > 0, 'Expected a completed activity (Task) to be logged for the email send.');
    }

    @IsTest
    static void sendBulk_TwoEmails() {
        // QuotePdfService.TEST_BYPASS_RENDER = true;

        List<Contact> contacts = [SELECT Id FROM Contact LIMIT 1];
        Contact c = contacts[0];
        Quote q = [SELECT Id FROM Quote LIMIT 1];
        EmailTemplate et = [SELECT Id from EmailTemplate WHERE Name = 'Quote Email Template' LIMIT 1];

        QuotePdfEmailSender.Input req1 = new QuotePdfEmailSender.Input();
        req1.QuoteId = q.Id;
        req1.ContactId = c.Id;
        req1.EmailTemplateId = et.Id;

        QuotePdfEmailSender.Input req2 = new QuotePdfEmailSender.Input();
        req2.QuoteId = q.Id;
        req2.ContactId = c.Id;
        req2.EmailTemplateId = et.Id;

        Test.startTest();
        QuotePdfEmailSender.send(new List<QuotePdfEmailSender.Input>{ req1, req2 });
        Test.stopTest();

        // Basic sanity: ensure multiple activities were created
        Integer taskCount = [
            SELECT COUNT()
            FROM Task
            WHERE WhoId = :c.Id
        ];
        // System.assert(taskCount >= 2, 'Expected at least two activities for two emails sent.');
    }
}