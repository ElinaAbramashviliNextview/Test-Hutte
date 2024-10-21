@isTest 
private class MdlTest {

	@isTest
	private static void BaseResponseTest() {
		Mdl.DriveTokenRefreshResponse dtrr = new Mdl.DriveTokenRefreshResponse();
		dtrr.authTkn = 't';
		dtrr.validTo = System.now();

		Mdl.DriveOAuthResponse dor = new Mdl.DriveOAuthResponse();
		dor.access_token = 't';
		dor.expires_in = 1;
		dor.refresh_token = 't';
		dor.scope = 't';
		dor.token_type = 't';

		Mdl.DriveCreateFolderResponse dcfr = new Mdl.DriveCreateFolderResponse();
		dcfr.kind = 't';
		dcfr.id = 't';
		dcfr.name = 't';
		dcfr.mimeType = 't';

		Mdl.CreateFolderResult cfr = new Mdl.CreateFolderResult();
		cfr.folderID = 't';

		Mdl.QA_InitResponseMdl qirm = new Mdl.QA_InitResponseMdl();
		qirm.stagePickVals =  new Mdl.PickVal[]{};
		qirm.isSuccess = true;
		qirm.msg = 't';

		Mdl.QA_GetDuplicatesResult qgdr = new Mdl.QA_GetDuplicatesResult();
		qgdr.duplicateOpps =  new Opportunity[]{};
		qgdr.isSuccess = true;
		qgdr.isOppCreated = true;
		qgdr.newOppId = UserInfo.getUserId();
		qgdr.msg = 't';

		Mdl.QA_CreateOppResult cor = new Mdl.QA_CreateOppResult();
		cor.newOppId = UserInfo.getUserId();
		cor.isSuccess = true;
		cor.msg = 't';

		Mdl.PickVal pv = new Mdl.PickVal('a', 'b');


	}

	@isTest
	private static void QuoteLineMdlTest(){
		Mdl.QuoteLineItemMdl qlim = new Mdl.QuoteLineItemMdl();		
		qlim.ProductName = 'test';
		qlim.ProductFamily = 'test';
		qlim.ProductDescriptionCZ = 'test';
		qlim.ProductDescriptionEN = 'test';
		qlim.Description = 'test';
		qlim.Quantity = 'test';
		qlim.ListPrice = 'test';
		qlim.UnitPrice = 'test';
		qlim.TotalPrice = 'test';
		qlim.RowDiscount = 'test';
		qlim.RowTotalPrice = 'test';
		qlim.DiscountUnitPrice = 'test';

		Mdl.SpecificationMdl sm = new Mdl.SpecificationMdl();
		sm.qli = new QuoteLineItem();
		//sm.boms = new BOM__c[]{};
		sm.productCount = 'tets';
	}
}