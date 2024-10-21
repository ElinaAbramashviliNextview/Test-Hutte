@isTest
private class SpecificationPdfControllerTest {
	@isTest
    private static void SpecificationPdfControllerTest() {
    	SyncServiceSettings__c stt = new SyncServiceSettings__c();
        stt.Name = 'AccountToSAP';
        stt.DisableSync__c = true;
        insert stt;
        
        Opportunity opp = new Opportunity(StageName='Qualification', Name='Opp Test', CloseDate=Date.newInstance(2019, 8, 24));
        insert opp;
		Quote qt = new Quote(Name='Quote Test', OpportunityId=opp.Id);
        insert qt;
		
        Id pricebookId = Test.getStandardPricebookId();
        Product2 prod = new Product2(Name='Product', IsActive=true, Type__c = 'V-VYROBEK');
        insert prod;
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id=:prod.Id AND CurrencyIsoCode=:Cst.CURR_CZK AND IsActive=true LIMIT 1];
        
        QuoteLineItem qlis = new QuoteLineItem(QuoteId=qt.Id, PricebookEntryId=pbe.Id, Product2Id=prod.Id, Quantity=2, UnitPrice=100.00);
        insert qlis;
        
        ContentVersion cvOne = new ContentVersion(VersionData = Blob.valueOf('ngadgnk'), Title = 'Specification', PathOnClient = 'PathOnClient');
        insert cvOne;
        ContentVersion cvTwo = new ContentVersion(VersionData = Blob.valueOf('ngadgnk'), Title = 'SpecificationDetail', PathOnClient = 'PathOnClient');
        insert cvTwo;
        
        ContentDocument[] cDoc = [SELECT Id FROM ContentDocument LIMIT 2];
        
        ContentDocumentLink cdlOne = new ContentDocumentLink(ContentDocumentId=cDoc[0].Id, LinkedEntityId=prod.Id, ShareType='V', Visibility='AllUsers');
        insert cdlOne;
        ContentDocumentLink cdlTwo = new ContentDocumentLink(ContentDocumentId=cDoc[1].Id, LinkedEntityId=prod.Id, ShareType='V', Visibility='AllUsers');
        insert cdlTwo;
        
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(qt);
        SpecificationPdfController ctrl = new SpecificationPdfController(stdCtrl);
    } 
}