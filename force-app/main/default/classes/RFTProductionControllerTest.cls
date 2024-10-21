@isTest
public class RFTProductionControllerTest  {

	@IsTest
	public static void testMethods(){
		RequestForTechnician__c rft = new RequestForTechnician__c();	
		insert rft;
		Product2 prod = new Product2(Name='MICRO OFFICE',IsActive=true,ProductCode='ABCD',SAPId__c='A0123',UnitPriceCZK__c=1000,UnitPriceEUR__c=20, RequestForTechnicianId__c = rft.Id);
		insert prod;
		RFTProductListController.auraGetProds(rft.Id);
		RFTProductListController.auraDeleteProduct(rft.Id, prod.Id);
	}
}