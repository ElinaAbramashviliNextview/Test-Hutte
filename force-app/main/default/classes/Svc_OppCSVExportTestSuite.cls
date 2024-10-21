@isTest
public class Svc_OppCSVExportTestSuite  {
	@IsTest
	public static void SchedulableTests(){
		OppCSVExportSchedulable1.scheduleJob();
		OppCSVExportSchedulable1.cancel();

		OppCSVExportSchedulable2.scheduleJob();
		OppCSVExportSchedulable2.cancel();

		OppCSVExportSchedulable3.scheduleJob();
		OppCSVExportSchedulable3.cancel();

		OppCSVExportSchedulable4.scheduleJob();
		OppCSVExportSchedulable4.cancel();
	}

	@isTest
	public static void Svc_OppCSVExportTest(){
		Svc_OppCSVExport.exportOppsToGdrive();
	}

	@isTest
	public static void Svc_OppCSVExportTest2(){
		GoogleDriveAuth__c sett = new GoogleDriveAuth__c(Name='default', TokenExpireDate__c = System.now().addDays(1));
		insert sett;
		Test.startTest();
		
		Product2 prod = new Product2(Name='MICRO OFFICE',IsActive=true,ProductCode='ABCD',SAPId__c='A0123',UnitPriceCZK__c=1000,UnitPriceEUR__c=20);
		insert prod;
		Product2 subProd = new Product2(Name='Cloth for MO',IsActive=true,ProductCode='CFMO',SAPId__c='A0456', Specification__c= '10;11');
		insert subProd;
		BOM__c bom = new BOM__c(BundleId__c=prod.Id,BundleItemId__c=subProd.Id,Quantity__c=10);
		insert bom;

		Id pricebookId = Test.getStandardPricebookId();
		String currForTest = Cst.CURR_CZK;

		// Update product price for EUR
		prod.UnitPriceEUR__c = 15;
		update prod;

		PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id=:prod.Id AND CurrencyIsoCode=:currForTest LIMIT 1];
		
		Opportunity opp = new Opportunity(StageName='Qualification', Name='Opp Test', CloseDate=Date.newInstance(2019, 8, 24));	
		insert opp;
		Quote qt = new Quote(Name='Quote Test', OpportunityId=opp.Id, Pricebook2Id = pricebookId);
		insert qt;
		opp.SyncedQuoteId = qt.Id;
		update opp;
		RequestForTechnician__c rft = new RequestForTechnician__c(DescriptionForTechnician__c = 'Test', QuoteId__c = qt.Id, Status__c='Done', CurrencyIsoCode=opp.CurrencyIsoCode);
		insert rft;
		Product2 prod2 = new Product2(Name='MICRO OFFICE',IsActive=true,ProductCode='ABCD',SAPId__c='A0123',UnitPriceCZK__c=1000,UnitPriceEUR__c=20, RequestForTechnicianId__c = rft.Id);
		insert prod2;
		rft.Status__c = Cst.RFT_STATUS_DONE;
		update rft;

		QuoteLineItem qli = new QuoteLineItem(QuoteId=qt.Id, Quantity=10, UnitPrice=10, Product2Id=prod.Id, PricebookEntryId = pbe.Id);
		insert qli;
		QuoteLineSubItem__c qlsi = new QuoteLineSubItem__c(QuoteLineItemId__c=qli.Id);
		insert qlsi;
		Invoice__c inv = new Invoice__c(OpportunityId__c = opp.Id, IsProforma__c = true);
		insert inv;

		Svc_OppCSVExport.exportOppsToGdrive();
		Test.stopTest();
	}


	@isTest
	public static void Svc_OppCSVExportTest3(){
		GoogleDriveAuth__c sett = new GoogleDriveAuth__c(Name='default', TokenExpireDate__c = System.now().addDays(1));
		insert sett;
		CNBRatesSyncSettings__c sett2 = new CNBRatesSyncSettings__c(Name ='default', isAdvancedCurrRateSync__c = true);
		insert sett2;
		Test.startTest();
		
		Product2 prod = new Product2(Name='MICRO OFFICE',IsActive=true,ProductCode='ABCD',SAPId__c='A0123',UnitPriceCZK__c=1000,UnitPriceEUR__c=20);
		insert prod;
		Product2 subProd = new Product2(Name='Cloth for MO',IsActive=true,ProductCode='CFMO',SAPId__c='A0456', Specification__c= '10;11');
		insert subProd;
		BOM__c bom = new BOM__c(BundleId__c=prod.Id,BundleItemId__c=subProd.Id,Quantity__c=10);
		insert bom;

		Id pricebookId = Test.getStandardPricebookId();
		String currForTest = Cst.CURR_CZK;

		// Update product price for EUR
		prod.UnitPriceEUR__c = 15;
		update prod;

		PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id=:prod.Id AND CurrencyIsoCode=:currForTest LIMIT 1];
		
		Opportunity opp = new Opportunity(StageName='Qualification', Name='Opp Test', CloseDate=Date.newInstance(2019, 8, 24));	
		insert opp;
		Quote qt = new Quote(Name='Quote Test', OpportunityId=opp.Id, Pricebook2Id = pricebookId);
		insert qt;
		opp.SyncedQuoteId = qt.Id;
		update opp;
		RequestForTechnician__c rft = new RequestForTechnician__c(DescriptionForTechnician__c = 'Test', QuoteId__c = qt.Id, Status__c='Done', CurrencyIsoCode=opp.CurrencyIsoCode);
		insert rft;
		Product2 prod2 = new Product2(Name='MICRO OFFICE',IsActive=true,ProductCode='ABCD',SAPId__c='A0123',UnitPriceCZK__c=1000,UnitPriceEUR__c=20, RequestForTechnicianId__c = rft.Id);
		insert prod2;
		rft.Status__c = Cst.RFT_STATUS_DONE;
		update rft;

		QuoteLineItem qli = new QuoteLineItem(QuoteId=qt.Id, Quantity=10, UnitPrice=10, Product2Id=prod.Id, PricebookEntryId = pbe.Id);
		insert qli;
		QuoteLineSubItem__c qlsi = new QuoteLineSubItem__c(QuoteLineItemId__c=qli.Id);
		insert qlsi;
		Invoice__c inv = new Invoice__c(OpportunityId__c = opp.Id, IsProforma__c = true);
		insert inv;

		Svc_OppCSVExport.exportOppsToGdrive();
		Test.stopTest();
	}
}