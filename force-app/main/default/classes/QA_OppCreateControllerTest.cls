@isTest 
private class QA_OppCreateControllerTest {

    @isTest
    private static void auraInitTest() {
        Account acc = new Account(Name='Test',BillingCity='Praha');
        insert acc;
        QA_OppCreateController.auraInit(acc.Id);
    }

    @IsTest
    private static void auraGetAccountCurrencyTest(){
        Account acc = new Account(Name='Test',BillingCity='Praha');
        insert acc;
        QA_OppCreateController.auraGetAccountCurrency(acc.Id);
    }
    
    @isTest
    private static void auraGetDuplicatesTest() {
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.SetupOwnerId = UserInfo.getUserId();
        ts.Disable_All__c = true;
        insert ts;
        
        Test.startTest();
        Account a = new Account(Name = 'Test',BillingCity='Praha');
        insert a;
        Opportunity o = new Opportunity();
        o.Name = 'test';
        o.AccountId = a.Id;
        o.City__c = 'City';
        o.Country__c = 'Country';
        o.PostalCode__c = 'PostalCode';
        o.State__c = 'State';
        o.Street__c = 'Street';
        o.StageName = 'Quoted';
        o.CloseDate = System.today();
        QA_OppCreateController.auraGetDuplicates(o);
        Test.stopTest();
    }

    @isTest
    private static void auraCreateOppTest() {
        TriggerSettings__c ts = new TriggerSettings__c();
        ts.SetupOwnerId = UserInfo.getUserId();
        ts.Disable_All__c = true;
        insert ts;
        
        Test.startTest();
        // create and insert 1st opp
        Account a = new Account(Name = 'Test',BillingCity='Praha');
        insert a;
        Opportunity o = new Opportunity();
        o.Name = 'test';
        o.AccountId = a.Id;
        o.City__c = 'City';
        o.Country__c = 'Country';
        o.PostalCode__c = 'PostalCode';
        o.State__c = 'State';
        o.Street__c = 'Street';
        o.StageName = 'Quoted';
        o.CloseDate = System.today();
        QA_OppCreateController.auraGetDuplicates(o);

        // create 2nd opp with 1st opp relation (create new parent opp)
        Opportunity o2 = new Opportunity();
        o2.Name = 'test';
        o2.AccountId = a.Id;
        o2.City__c = 'City';
        o2.Country__c = 'Country';
        o2.PostalCode__c = 'PostalCode';
        o2.State__c = 'State';
        o2.Street__c = 'Street';
        o2.StageName = 'Quoted';
        o2.CloseDate = System.today();
        QA_OppCreateController.auraCreateOpp(o2, o.Id);

        // create 3rd opp with 1st opp relation (parent opp already exists)
        Opportunity o3 = new Opportunity();
        o3.Name = 'test';
        o3.AccountId = a.Id;
        o3.City__c = 'City';
        o3.Country__c = 'Country';
        o3.PostalCode__c = 'PostalCode';
        o3.State__c = 'State';
        o3.Street__c = 'Street';
        o3.StageName = 'Quoted';
        o3.CloseDate = System.today();

        QA_OppCreateController.auraCreateOpp(o3, o.Id);

        // create 4th opp with no relation (insert standalone opp)
        Opportunity o4 = new Opportunity();
        o4.Name = 'test';
        o4.AccountId = a.Id;
        o4.City__c = 'City';
        o4.Country__c = 'Country';
        o4.PostalCode__c = 'PostalCode';
        o4.State__c = 'State';
        o4.Street__c = 'Street';
        o4.StageName = 'Quoted';
        o4.CloseDate = System.today();
        
        QA_OppCreateController.auraCreateOpp(o4, null);
        Test.stopTest();


    }

}