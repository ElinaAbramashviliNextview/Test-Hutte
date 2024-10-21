@isTest 

public with sharing class QuoteCloneControllerTest {

    @isTest
    private static void auraGetOppCurrencyTest() {	
        Opportunity opp = new Opportunity(StageName='Qualification', Name='Opp Test', CloseDate=Date.newInstance(2019, 8, 24));
        insert opp;
        String qt2 = QuoteCloneController.auraGetOppCurrency(opp.Id);
    }

    @isTest
    private static void auraCloneTest(){
        Id pricebookId = Test.getStandardPricebookId();
        String currForTest = Cst.CURR_CZK;
        Product2 prod = new Product2(Name='MICRO OFFICE',IsActive=true,ProductCode='ABCD',SAPId__c='A0123',UnitPriceCZK__c=1000,UnitPriceEUR__c=20);
		insert prod;
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id=:prod.Id AND CurrencyIsoCode=:currForTest LIMIT 1];
		Product2 subProd = new Product2(Name='Cloth for MO',IsActive=true,ProductCode='CFMO',SAPId__c='A0456');
        insert subProd;
        Opportunity opp = new Opportunity(StageName='Qualification', Name='Opp Test', CloseDate=Date.newInstance(2019, 8, 24));
        insert opp;
        Quote qt = new Quote(Name='Quote Test', OpportunityId=opp.Id, Pricebook2Id = pricebookId);
		insert qt;
		QuoteLineItem qli = new QuoteLineItem(QuoteId=qt.Id, Quantity=10, UnitPrice=10, Product2Id=prod.Id, PricebookEntryId = pbe.Id, RowDiscount__c=0.00, RowTotalPrice__c=10, LineCost__c=10);
		insert qli;
		QuoteLineItem qli2 = new QuoteLineItem(QuoteId=qt.Id, Quantity=10, UnitPrice=10, RowTotalPrice__c = 10, Product2Id=prod.Id, PricebookEntryId = pbe.Id, RowDiscount__c=0.00, LineCost__c=10);
		insert qli2;
		QuoteLineSubItem__c qlsi = new QuoteLineSubItem__c(QuoteLineItemId__c=qli.Id);
		insert qlsi;
        String qt2 = QuoteCloneController.auraClone(qt.Id, opp.Id);
    }
    
}