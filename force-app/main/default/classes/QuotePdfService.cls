// QuotePdfService.cls
public with sharing class QuotePdfService {

    public class Result {
        @AuraEnabled public Id contentDocumentId;
        @AuraEnabled public Id contentVersionId;
        @AuraEnabled public String fileName;
        @AuraEnabled public String publicUrl; // if ContentDistribution created
    }

    // Map template to VF page (or use Custom Metadata for admin control)
    private static String pageNameForTemplate(String templateName) {
        // single dynamic page:
        return 'QuotePdf';
        // OR per-template:
        // if (templateName == 'Premium') return 'QuotePdf_Premium';
        // return 'QuotePdf_Standard';
    }

    // Core function: render, save, (optionally) publish a public link
    public static Result generate(Id quoteId, Boolean createPublicLink) {

        Result r = new Result();

        Quote q = [SELECT Id, Name, QuoteNumber, Quote_Template__c, Quote_Link__c FROM Quote WHERE Id = :quoteId LIMIT 1];
        String pageName = pageNameForTemplate(q.Quote_Template__c);
        PageReference pr = new PageReference(Site.getBaseUrl() + '/apex/QuotePdf');
        pr.getParameters().put('id', (String)quoteId);


        Blob pdfBlob;

        if(Test.isRunningTest() == true){
            pdfBlob  = Blob.toPdf('test');
        }else{
            // Render to PDF
            pdfBlob = pr.getContentAsPDF();
        }
        

        // Save as ContentVersion (File) related to Quote
        String fileName = 'Quote_' + (q.QuoteNumber!=null ? q.QuoteNumber : q.Name) + '.pdf';
        ContentVersion cv = new ContentVersion(
            Title = fileName.replace('.pdf',''),
            PathOnClient = fileName,
            VersionData = pdfBlob,
            FirstPublishLocationId = quoteId // links file to the quote
        );
        insert cv;

        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        r.contentVersionId = cv.Id;
        r.contentDocumentId = cv.ContentDocumentId;
        r.fileName = fileName;

        System.System.debug(createPublicLink);

        if (createPublicLink) {
            ContentDistribution cd = new ContentDistribution(
                Name = fileName,
                ContentVersionId = cv.Id,
                PreferencesAllowOriginalDownload = true,
                PreferencesNotifyOnVisit = false,
                PreferencesLinkLatestVersion = true,
                PreferencesAllowPDFDownload = true,
                PreferencesPasswordRequired = false
                // ExpiryDate = System.today().addDays(30) // optional
            );
            insert cd;

            ContentDistribution cdlink = [SELECT Id, DistributionPublicUrl FROM ContentDistribution WHERE Id = :cd.Id];
            r.publicUrl = cdlink.DistributionPublicUrl;
            q.Quote_Link__c = r.publicUrl;

            System.debug(cd.Id);

            update q;
        }
        return r;
    }
}