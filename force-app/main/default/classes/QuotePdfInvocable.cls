// QuotePdfInvocable.cls
public with sharing class QuotePdfInvocable {
    public class Input {
        @InvocableVariable(required=true) public Id QuoteId;
        @InvocableVariable public Boolean CreatePublicLink;
    }
    public class Output {
        @InvocableVariable public Id ContentDocumentId;
        @InvocableVariable public Id ContentVersionId;
        @InvocableVariable public String PublicUrl;
        @InvocableVariable public String FileName;
    }

    @InvocableMethod(label='Generate Quote PDF')
    public static List<Output> run(List<Input> inputs) {
        List<Output> results = new List<Output>();
        for (Input i : inputs) {
            QuotePdfService.Result r = QuotePdfService.generate(i.QuoteId, i.CreatePublicLink == true);
            Output o = new Output();
            o.ContentDocumentId = r.contentDocumentId;
            o.ContentVersionId = r.contentVersionId;
            o.PublicUrl = r.publicUrl;
            o.FileName = r.fileName;
            results.add(o);
        }
        return results;
    }
}