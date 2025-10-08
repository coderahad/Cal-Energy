// QuotePdfEmailSender.cls
public with sharing class QuotePdfEmailSender {
    public class Input {
        @InvocableVariable(required=true) public Id QuoteId;
        @InvocableVariable(required=true) public Id ContactId;
        @InvocableVariable(required=true) public Id EmailTemplateId;
        @InvocableVariable public Boolean CreatePublicLink;
    }

    @InvocableMethod(label='Send Quote Email With PDF')
    public static void send(List<Input> inputs) {
        for (Input i : inputs) {
            // ensure file exists

        
            QuotePdfService.Result r = QuotePdfService.generate(i.QuoteId, true);

            Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
            m.setTemplateId(i.EmailTemplateId);
            m.setTargetObjectId(i.ContactId);
            m.setWhatId(i.QuoteId);
            m.setSaveAsActivity(true);

            // attach the file
            List<Messaging.EmailFileAttachment> atts = new List<Messaging.EmailFileAttachment>();
            ContentVersion cv = [SELECT Id, VersionData, Title FROM ContentVersion WHERE Id = :r.contentVersionId];
            Messaging.EmailFileAttachment a = new Messaging.EmailFileAttachment();
            a.setFileName(cv.Title + '.pdf');
            a.setBody(cv.VersionData);
            a.setContentType('application/pdf');
            atts.add(a);
            m.setFileAttachments(atts);

            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { m }, false);
        }
    }
}