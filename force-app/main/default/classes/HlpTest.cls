@isTest
public class HlpTest  {
    @isTest
    private static void GetStringWithLengthTest() {
        Hlp.getStringWithLength('xxx', 2);
        Hlp.getStringWithLength('', 2);

    }
    
    @isTest
    private static void GetPickValsMapTest() {
        Hlp.getPickValsMap('Opportunity', 'StageName');
    }


    @isTest
    private static void GetPickValsTest() {
        Hlp.getPickVals('Opportunity', 'StageName');
    }

    @isTest
    private static void GetPickValuesOptionsTest(){
        SyncServiceSettings__c stt = new SyncServiceSettings__c();
        stt.Name = 'AccountToSAP';
        stt.DisableSync__c = true;
        insert stt;

        Opportunity opp = new Opportunity(StageName='Qualification', Name='Opp Test', CloseDate=Date.newInstance(2019, 8, 24)); 
        insert opp;
    }

    @isTest
    private static void AfterOrderInsertTest(){
        Contact c = new Contact(LastName='Test', Email='e@e.cz', Phone='123456789', Role__c='End user');
        insert c;
        Order__c ord = new Order__c(Name='Test', RealizationStartDate__c = System.today(), RealizationEndDate__c = System.today(), ShippingAddressTxt__c = 'test', PrimaryContactId__c = c.Id);
        insert ord;
    }

    @isTest
    private static void getFormatedSubstringTest(){
        String str = 'Testovací stgring';
        String result = Hlp.getFormatedSubstring(str, 5);
    }

    @isTest
    private static void handleOppHierarchyCloseTest(){
        Account acc = new Account(Name='Test',BillingCity='Praha');
        insert acc;
        Opportunity opp = new Opportunity(StageName='Qualification', Name='Opp Test', CloseDate=Date.newInstance(2019, 8, 24), AccountId = acc.Id, Amount=10, CurrencyIsoCode='CZK');   
        insert opp;
        Opportunity opp2 = new Opportunity(StageName='Qualification', Name='Opp Test', CloseDate=Date.newInstance(2019, 8, 24), AccountId = acc.Id, ParentOpportunityId__c=opp.Id, Amount=10, CurrencyIsoCode='CZK');   
        insert opp2;
        Hlp.handleOppHierarchyClose(new Set<Id>{opp.Id}, new Set<Id>{opp2.Id});
    }

    @IsTest
    private static void should_returnValue_When_GetDatedCZKValue_ReturnZero(){
        Account acc = new Account(Name='Test', BillingCity = 'New York');
        insert acc;
        Opportunity opp = new Opportunity(StageName='Qualification', Name='Opp Test', CloseDate=Date.newInstance(2019, 8, 24), AccountId = acc.Id, Amount=10, CurrencyIsoCode='CZK');
        insert opp;
        Opportunity opp2 = new Opportunity(StageName='Qualification', Name='Opp Test', CloseDate=Date.newInstance(2019, 8, 24), AccountId = acc.Id, ParentOpportunityId__c=opp.Id, Amount=10, CurrencyIsoCode='CZK');
        insert opp2;
        Quote quote = new Quote(ProjectSalesFee__c = 12, ProjectSalesFeeValue__c = 12, QuoteTotalDiscount__c = 3, CurrencyIsoCode = 'CZK', OpportunityId = opp2.Id);
        insert quote;
        insert new ProjectSalesFee__c(Name = 'Test', LowerRange__c = 3, HigherRange__c = 4, Reward__c = 5);
        Hlp.getDatedCZKValueFromSetQT(new Set<Id>{quote.Id});

        List<Quote> quotes = [SELECT Id, ProjectSalesFeeValue__c FROM Quote];
        System.assertEquals(0, quotes.get(0).ProjectSalesFeeValue__c, 'ProjectSalesFeeValue__c should be updated to 0 based on calculations.');
    }

    @IsTest
    private static void should_returnFalse_When_areValuesDifferentGetsTwoDifferentValues() {
        Boolean result = Hlp.areValuesDifferent(null, 'Test2', false);

        Assert.areEqual(true, result, 'True should be returned as values are different');
    }

    @IsTest
    private static void should_returnTrue_When_areValuesDifferentGetsTwoSameValues() {
        Boolean result = Hlp.areValuesDifferent(123, 123, false);

        Assert.areEqual(false, result, 'False should be returned as values are the same');
    }

    @IsTest
    private static void should_returnFalse_When_areValuesDifferentGetsTwoDifferentValuesButTreatNullAsNoChangeIsSet() {
        Boolean result = Hlp.areValuesDifferent('Test1', null, true);

        Assert.areEqual(false, result, 'False should be returned as treatNullAsNoChange is set and comparedValue is null');
    }

}