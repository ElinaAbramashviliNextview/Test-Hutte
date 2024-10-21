@isTest 
private class QuoteManagerControllerTest {

    @isTest
    private static void auraGetDataTest() { 
        
		Opportunity o = new Opportunity(Name = 'Test', CloseDate = System.today(), StageName = 'Qualification');
		insert o;
        Quote q = new Quote(Name = 'test', OpportunityId = o.Id);
		insert q;
        // auraGetData Test
        SyncServiceSettings__c stt = new SyncServiceSettings__c();
        stt.Name = 'AccountToSAP';
        stt.DisableSync__c = true;
        insert stt;
        Profile[] prof = [SELECT Id FROM Profile];
        User u = new User(LastName = 'test', ProfileId = prof[0].Id, Username='test@silentlab.cz', EmailEncodingKey = 'UTF-8', Email='test@test.cz', Alias='test', CommunityNickname='test', TimeZoneSidKey='Europe/Berlin', LocaleSidKey='en_US', LanguageLocaleKey='en_US');
        insert u;
        Product2 prod = new Product2(Name='MICRO OFFICE',IsActive=true,ProductCode='ABCD',SAPId__c='A0123',UnitPriceCZK__c=1000,UnitPriceEUR__c=20);
        insert prod;
        Product2 subProd = new Product2(Name='Cloth for MO',IsActive=true,ProductCode='CFMO',SAPId__c='A0456');
        insert subProd;
        BOM__c bom = new BOM__c(BundleId__c=prod.Id,BundleItemId__c=subProd.Id,Quantity__c=10);
        insert bom;

        Id pricebookId = Test.getStandardPricebookId();
        String currForTest = Cst.CURR_CZK;

        // Update product price for EUR
        prod.UnitPriceEUR__c = 15;
        update prod;

        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id=:prod.Id AND CurrencyIsoCode=:currForTest LIMIT 1];
        
        Account acc = new Account(Name='Test',BillingCity='Praha');
        insert acc; 
        Opportunity opp = new Opportunity(StageName='Qualification', Name='Opp Test', CloseDate=Date.newInstance(2019, 8, 24), AccountId = acc.Id); 
        insert opp;
        Quote qt = new Quote(Name='Quote Test', OpportunityId=opp.Id, Pricebook2Id = pricebookId);
        insert qt;
        QuoteLineItem qli = new QuoteLineItem(QuoteId=qt.Id, Quantity=10, UnitPrice=10, Product2Id=prod.Id, PricebookEntryId = pbe.Id);
        insert qli;
        QuoteLineItem qli2 = new QuoteLineItem(QuoteId=qt.Id, Quantity=10, UnitPrice=10, RowTotalPrice__c = 0, Product2Id=prod.Id, PricebookEntryId = pbe.Id);
        insert qli2;
        QuoteLineSubItem__c qlsi = new QuoteLineSubItem__c(QuoteLineItemId__c=qli.Id);
        insert qlsi;
        QuoteManagerController.auraGetData(qt.Id);
    
        
        // auraSave Test
        Mdl.QuoteLineMdl[] qmm = new Mdl.QuoteLineMdl[]{};
        String qmmString = JSON.serialize(qmm);
        Mdl.QuoteLineMdl[] qmms = new Mdl.QuoteLineMdl[]{};
        String quoteString = JSON.serialize(qt);
        String transportString = JSON.serialize(qli2);
        QuoteManagerController.auraSave(qmmString, qmms, quoteString, transportString, false, 100);
        QuoteManagerController.auraSave(qmmString, qmms, quoteString, transportString, true, 100);


        // auraGetProdDescs Test
        QuoteManagerController.auraGetProductMdl(prod.Id, currForTest);

        // auraGetNewProduct Test
        QuoteManagerController.auraGetProductByPBE(prod.Id, currForTest);
        
        // auraGetCZKReward Test
        QuoteManagerController.auraGetCZKReward(1000, 'CZK');
    }
}