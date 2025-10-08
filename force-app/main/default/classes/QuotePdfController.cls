// QuotePdfController.cls
public with sharing class QuotePdfController {
    public Id quoteId { get; private set; }
    public String templateName { get; private set; }
    public String SL { get; private set; }
    public Quote quote { get; private set; }

    

    public QuotePdfController() {
        Quote q;
        if(Test.isRunningTest() == false){
            quoteId = (Id)ApexPages.currentPage().getParameters().get('id');
            q = [
                SELECT Id, QuoteNumber, Name, Status, TotalPrice, Quote_Template__c, ExpirationDate, Contact.Name, Email, Opportunity.Owner.Name, Account.Name, 
                BillingStreet, BillingCity, BillingState, BillingPostalCode, Work_Order_Number__c, PO_Number__c,
                ShippingStreet, ShippingCity , ShippingCountry , ShippingState , ShippingPostalCode, Phone, Description, CreatedBy.Name, Opportunity.CloseDate,
                Account.Payment_Terms__c, Opportunity.Name, CreatedDate, Opportunity.Service_Locstion_Address__City__s, Opportunity.Service_Locstion_Address__StateCode__s,
                Opportunity.Service_Locstion_Address__Street__s, Opportunity.Service_Locstion_Address__PostalCode__s, Opportunity.Service_Locstion_Address__CountryCode__s
                FROM Quote
                WHERE Id = :quoteId
                LIMIT 1
            ];
        }else{



            q = [
                SELECT Id, QuoteNumber, Name, Status, TotalPrice, Quote_Template__c, ExpirationDate, Contact.Name, Email, Opportunity.Owner.Name, Account.Name, Work_Order_Number__c, PO_Number__c,
                ShippingStreet, ShippingCity , ShippingCountry , ShippingState , ShippingPostalCode, Phone, Description, CreatedBy.Name, Opportunity.CloseDate,
                Account.Payment_Terms__c, Opportunity.Name, CreatedDate, Opportunity.Service_Locstion_Address__City__s, Opportunity.Service_Locstion_Address__StateCode__s
                FROM Quote
                LIMIT 1
            ];

            quoteId = q.Id;
        }

        SL = q.Opportunity.Service_Locstion_Address__City__s + ', ' + q.Opportunity.Service_Locstion_Address__StateCode__s;

        quote = q;
        templateName = q.Quote_Template__c;
        
    }
}