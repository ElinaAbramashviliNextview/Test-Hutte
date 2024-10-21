@isTest
public class NewProductTechniciansControllerTest {
	@isTest
    public static void testMethodS() {
		TemporaryRecord__c tmprec = new TemporaryRecord__c(Name = Cst.RFT_TMP_RECORD_NAME);
		insert tmprec;
		NewProductTechniciansController.auraGetInitData();
        RequestForTechnician__c req = new RequestForTechnician__c();
        insert req;
        Product2 prod1 = new Product2(Name='Product', IsActive=true, RequestForTechnicianId__c=req.Id);
        insert prod1;
        Product2 prod2 = new Product2(Name='Product2', IsActive=true, UnitCost__c=100.00);
        insert prod2;
        NewProductTechniciansController.auraGetProductDetail(prod1.Id);
        NewProductTechniciansController.auraGetProductDetail(null);
        NewProductTechniciansController.auraGetSearchResult('M-AKU_PENA', '1', 'AAA');
        Mdl.RFTMdl model = new Mdl.RFTMdl();
        model.prod = prod1;
        BOM__c[] bom = new BOM__c[]{new BOM__c (BundleId__c=prod1.Id,BundleItemId__c=prod2.Id, Quantity__c=2)};
        insert bom;
		ProductDescription__c[] pds = new ProductDescription__c[]{new ProductDescription__c(TitleCZ__c = 'Test', Name = 'test')};
		insert pds;
        
		String guid = Hlp.NewGuid();
		ContentVersion cv = new ContentVersion(VersionData = Blob.valueOf('ngadgnk'), Title = 'TestVersion', PathOnClient = 'PathOnClient', RefId__c = guid);
		insert cv;
		ContentVersion cvm = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id];
		String[] cdIds = new String[]{};
		cdIds.add(cvm.ContentDocumentId);

        NewProducttechniciansController.auraSaveBundle(JSON.serialize(model), JSON.serialize(bom), JSON.serialize(pds), req.Id, guid);
		NewProducttechniciansController.auraUploadFile(cdIds ,guid);
    }
}