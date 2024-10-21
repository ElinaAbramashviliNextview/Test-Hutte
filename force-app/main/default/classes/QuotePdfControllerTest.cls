@isTest 
private class QuotePdfControllerTest {

    @isTest
    private static void QuotePdfControllerTest() {
    SyncServiceSettings__c stt = new SyncServiceSettings__c();
        stt.Name = 'AccountToSAP';
        stt.DisableSync__c = true;
        insert stt;

        Opportunity opp = new Opportunity(StageName='Qualification', Name='Opp Test', CloseDate=Date.newInstance(2019, 8, 24)); 
        insert opp;
        Quote qt = new Quote(Name='Quote Test', OpportunityId=opp.Id, Language__c='cs');
        insert qt;
        
        Id pricebookId = Test.getStandardPricebookId();
        Product2 prod = new Product2(Name='Product', IsActive=true);
        insert prod;
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id=:prod.Id AND CurrencyIsoCode=:Cst.CURR_CZK AND IsActive=true LIMIT 1];
        
        QuoteLineItem qlis = new QuoteLineItem(QuoteId=qt.Id, PricebookEntryId=pbe.Id, Product2Id=prod.Id, Quantity=2, UnitPrice=100.00, UnitPrice__c=100.00, RowTotalPrice__c=200, RowDiscount__c=0);
        insert qlis;
        
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(qt);
        QuotePdfController ctrl = new QuotePdfController(stdCtrl);
    }
}