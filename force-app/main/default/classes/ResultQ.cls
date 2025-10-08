public class ResultQ {
        @AuraEnabled public Id contentDocumentId;
        @AuraEnabled public Id contentVersionId;
        @AuraEnabled public String fileName;
        @AuraEnabled public String publicUrl; // if ContentDistribution created
}