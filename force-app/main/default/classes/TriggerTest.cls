@isTest 
private class TriggerTest {

    @isTest
    private static void triggerTestMethod() {
        SyncServiceSettings__c[] stts = new SyncServiceSettings__c[]{};
        stts.add(new SyncServiceSettings__c(Name = 'AccountToSAP', DisableSync__c = true));
        stts.add(new SyncServiceSettings__c(Name = 'OrderToSAP', DisableSync__c = true));
        stts.add(new SyncServiceSettings__c(Name = 'ProductToSAP', DisableSync__c = false));
        insert stts;

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
        
        Opportunity opp = new Opportunity(StageName='Qualification', Name='Opp Test', CloseDate=Date.newInstance(2019, 8, 24), Realisation_Start_confirmed__c = true);
        insert opp;
        Quote qt = new Quote(Name='Quote Test', OpportunityId=opp.Id, Pricebook2Id = pricebookId, QuoteDiscount__c = 0);
        insert qt;
        Order__c ord = new Order__c(Name = 'Order Test', OpportunityId__c = opp.Id, QuoteId__c = qt.Id, ShippingAddressTxt__c = 'xxx', RealizationStartDate__c = Date.today(), RealizationEndDate__c = Date.today().addDays(2));
        insert ord;
        Invoice__c inv = new Invoice__c(Name = 'Invoice Test', OrderId__c = ord.Id);
        Insert inv;
        RequestForTechnician__c rft = new RequestForTechnician__c(DescriptionForTechnician__c = 'Test', QuoteId__c = qt.Id, Status__c='Done', CurrencyIsoCode=opp.CurrencyIsoCode);
        insert rft;
        rft.TechnicianId__c = u.Id;
        update rft;
        Product2 prod2 = new Product2(Name='MICRO OFFICE',IsActive=true,ProductCode='ABCD',SAPId__c='A0123',UnitPriceCZK__c=1000,UnitPriceEUR__c=20, RequestForTechnicianId__c = rft.Id);
        insert prod2;
        rft.Status__c = Cst.RFT_STATUS_DONE;
        update rft;

        QuoteLineItem qli = new QuoteLineItem(QuoteId=qt.Id, Quantity=10, UnitPrice=10, Product2Id=prod.Id, PricebookEntryId = pbe.Id, LineCost__c = 10);
        insert qli;
        QuoteLineSubItem__c qlsi = new QuoteLineSubItem__c(QuoteLineItemId__c=qli.Id);
        insert qlsi;

        Account a = new Account(Name='Test', VatNo__c = '1231244324', IsValidated__c=true,BillingCity='Praha');
        insert a;

        Contact c = new Contact(LastName='Lname', AccountId = a.Id, Role__c='End user');
        insert c;

        opp.StageName = 'Closed Won';
        opp.Street__c = 'street';
        opp.City__c = 'City';
        opp.PostalCode__c = '12345';
        opp.Country__c = 'Czech republic';
        opp.AccountId = a.Id;
        opp.OrderDueDate__c = System.today();
        opp.RealizationStartDate__c = System.today();
        opp.RealizationEndDate__c = System.today();
        opp.PrimaryContact__c = c.id;
        opp.SyncedQuoteId = qt.Id;

        update opp;
    }

    @IsTest
    private static void should_UpdateOpportunityAddressFields_when_UpdateQuoteAddressFieldsAreDifferentAndSyncAddressIsOn() {
        Id pricebookId = Test.getStandardPricebookId();

        Opportunity testOpportunity = new Opportunity(
                StageName='Qualification',
                Name='Opp Test',
                CloseDate = Datetime.now().addDays(30).date(),
                Realisation_Start_confirmed__c = true,
                Country__c = 'Poland',
                Street__c = 'Test2023'
            );

        insert testOpportunity;

        Quote testQuote = new Quote(
                Name='Quote Test',
                OpportunityId = testOpportunity.Id,
                Pricebook2Id = pricebookId,
                QuoteDiscount__c = 0,
                IsSendAddressToOpportunity__c = false,
                ShippingStreet = 'TestQuote',
                ShippingCity = 'TestCity',
                ShippingState = 'New York',
                ShippingPostalCode = '10022',
                ShippingCountry = 'United States'
            );

        insert testQuote;

        testOpportunity.SyncedQuoteId = testQuote.Id;

        update testOpportunity;

        Test.startTest();

        testQuote.IsSendAddressToOpportunity__c = true;
        update testQuote;

        Test.stopTest();

        Opportunity updatedOpportunity = [SELECT Id, Street__c, City__c, State__c, PostalCode__c, Country__c FROM Opportunity WHERE Name = 'Opp Test' LIMIT 1];

        Assert.areEqual('TestQuote', updatedOpportunity.Street__c, 'Street on opportunity should be updated with value from Quote!');
        Assert.areEqual('TestCity', updatedOpportunity.City__c, 'City on opportunity should be updated with value from Quote!');
        Assert.areEqual('New York', updatedOpportunity.State__c, 'State on opportunity should be updated with value from Quote!');
        Assert.areEqual('10022', updatedOpportunity.PostalCode__c, 'PostalCode on opportunity should be updated with value from Quote!');
        Assert.areEqual('United States', updatedOpportunity.Country__c, 'Country on opportunity should be updated with value from Quote!');
    }
}