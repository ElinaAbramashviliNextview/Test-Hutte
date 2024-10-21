@isTest
public with sharing class ProductUpdateControllerTest {
    
    @isTest
    public static void testMethods(){
        // auraGetInitData TEST
        TemporaryRecord__c tmp = new TemporaryRecord__c(Name=Cst.RFT_TMP_RECORD_NAME);
        insert tmp;
        ProductBulkUpdateController.auraGetInitData();

        // auraGetSearchResult TEST
        ProductBulkUpdateController.auraGetSearchResult('0', '0', 'aaa');

        // auraSendExport TEST
        Product2[] prods = new Product2[]{};
        Product2 prod1 = new Product2(Name='Product', IsActive=true);
        insert prod1;
        Product2 prod2 = new Product2(Name='Product2', IsActive=true, UnitCost__c=100.00);
        insert prod2;
        prods.add(prod1);
        prods.add(prod2);
        String data = JSON.serialize(prods);
        ProductBulkUpdateController.auraSendExport(data, 'test@test.cz');

        // auraProductProcessing TEST
        ContentVersion cv = new ContentVersion(VersionData = Blob.valueOf('"Id";"Name";"Specification__c";"BusinessName__c";"BusinessNameEN__c";"Description";"ProductDescriptionCZ__c";"ProductDescriptionEN__c";"Family";"UnitCost__c";"UnitPriceCZK__c";"UnitPriceEUR__c";"UnitPriceUSD__c";"IsActive";"IsDefault__c"'+'\n'+'"01t3Y00000GTjwaQAD";"aaa";"null";"test";"null";"sd";"<p>pd cz</p>";"<p>pd en</p>";"null";"1";"2";"3";"4";"true";"true"'), Title = 'ProductExport', PathOnClient = 'PathOnClient');
        insert cv;
        ContentDocument cDoc = [SELECT Id FROM ContentDocument LIMIT 1];
        System.debug('Content Document ' + cDoc.Id);
        ProductBulkUpdateController.auraProductProcessing(cDoc.Id);

        // auraUpdateProducts TEST
        GoogleDriveAuth__c sett = new GoogleDriveAuth__c(name = 'default', ProdSyncFolderEID__c = 'xxx', TokenExpireDate__c = System.now().addMinutes(20), AccessToken__c = 'xxx');
        insert sett;
		Test.setMock(HttpCalloutMock.class, new GoogleDriveHTTPCalloutMock('{"access_token":"MTQ0NjJkZmQ5OTM2NDE1ZTZjNGZmZjI3","token_type":"bearer","expires_in":3600,"refresh_token":"IwOGYzYTlmM2YxOTQ5MGE3YmNmMDFkNTVk","scope":"create"}'));

        Test.startTest();
        ProductBulkUpdateController.auraUpdateProducts(cDoc.Id, 'test@test.cz');
        Test.stopTest();
    }

    /*=================================================================================================*/
	/* CALLOUT MOCK - CALLOUT MOCK - CALLOUT MOCK - CALLOUT MOCK - CALLOUT MOCK - CALLOUT MOCK - CALLOUT
	/*=================================================================================================*/

	public class GoogleDriveHTTPCalloutMock implements HttpCalloutMock {
		protected Integer code;
		protected String status;
		protected String body;
		protected Map<String, String> responseHeaders;
		public GoogleDriveHTTPCalloutMock(String body) { this.code = 200; this.body = body; }
		public GoogleDriveHTTPCalloutMock(Integer code, String body) { this.code = code; this.body = body; }
		public GoogleDriveHTTPCalloutMock(Integer code, String status, String body, Map<String, String> responseHeaders) {
			this.code = code; this.status = status; this.body = body; this.responseHeaders = responseHeaders;
		}
		public HTTPResponse respond(HTTPRequest req) {
			HttpResponse res = new HttpResponse();
			if (responseHeaders != null) {
				for (String key : this.responseHeaders.keySet()) { res.setHeader(key, this.responseHeaders.get(key)); }
			}
			res.setBody(this.body);
			res.setStatusCode(this.code);
			if (String.isNotEmpty(this.status)) { res.setStatus(this.status); }
			return res;
		}
	}
}