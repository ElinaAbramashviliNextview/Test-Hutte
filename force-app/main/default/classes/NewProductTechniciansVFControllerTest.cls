@isTest 
private class NewProductTechniciansVFControllerTest {

	@isTest
	private static void constructorTest() {
		RequestForTechnician__c rft = new RequestForTechnician__c();	
		insert rft;
		Product2 prod = new Product2(Name='MICRO OFFICE',IsActive=true,ProductCode='ABCD',SAPId__c='A0123',UnitPriceCZK__c=1000,UnitPriceEUR__c=20, RequestForTechnicianId__c = rft.Id);
		insert prod;
		ApexPages.StandardController stdCtrl = new ApexPages.StandardController(rft);
		NewProductTechniciansVFController nptvfc = new NewProductTechniciansVFController(stdCtrl);
	}
}