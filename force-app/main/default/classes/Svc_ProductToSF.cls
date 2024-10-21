@RestResource(urlMapping='/sync/product')
global without sharing class Svc_ProductToSF  {
    private static String SVC_NAME = 'ProductToSF';
    private static SyncServiceSettings__c stt = SyncServiceSettings__c.getValues(SVC_NAME);
    // https://<org-domain>/services/apexrest/sync/product

	@HttpPost
    global static void doPost() {
        if(stt.DisableSync__c){ SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_ERROR, 503, 'ERROR: Service is disabled'); return; }

	    // Get valid settings
	    String validToken = 'Baerer '+stt.Token__c;
	    // Also for testing
	    if(Test.isRunningTest()){ validToken = 'Baerer '+'XXXXX'; }

	    RestRequest req = RestContext.request;
	    RestResponse res = RestContext.response;

	    String token = req.headers.get('token');
        String body = (req.requestBody != null) ? req.requestBody.toString() : '';
        System.debug('body: '+body);

        // Validate token
        if(String.isEmpty(token) || token != validToken){
            res.statusCode = 401;
            res.responseBody = Blob.valueOf('Invalid token - requested ('+token+')');
            return;
        }

        // Insert inbound records - lsit of Products
        String msg = 'SUSCCESS: Products synced.';
		String stackTrace;
		String status = Cst.STATUS_SUCCESS;
		String errStr = '';
        res.statusCode = 200;
        try{
			Mdl.SfProduct[] recsFromJson = (Mdl.SfProduct[])JSON.deserialize(SyncUtils.getValidJsonForCustomModel(body), Mdl.SfProduct[].class);

			// Get Existing records
			Set<String> exProdSAPIds = new Set<String>();
			Set<String> exBOMEIds = new Set<String>();
			Mdl.SfProduct[] recs = new Mdl.SfProduct[]{};
			for(Mdl.SfProduct r : recsFromJson){
				if(exProdSAPIds.contains(r.SAPId)){ continue; } // Skip duplicates
				exProdSAPIds.add(r.SAPId);
				recs.add(r);
				Mdl.SfBom[] sfBoms = (r.BOMs != null && r.BOMs.Records != null) ? r.BOMs.Records : new Mdl.SfBom[]{};
				for(Mdl.SfBom b : sfBoms){
					exProdSAPIds.add(b.BundleSAPId);
					exBOMEIds.add(r.SAPId+'-'+b.BundleItemSAPId+'-'+b.RowNumber);
				}
			}
			
			
			System.debug('exBOMEIds:'+exBOMEIds);
			
			BOM__c[] exBOMs = [SELECT Id,SAPId__c,EId__c, BundleSAPId__c, BundleItemSAPId__c, Position__c, RowNumber__c FROM BOM__c WHERE EId__c IN:exBOMEIds];
			Map<String,Id> exBOMsByEId = new Map<String,Id>(); // <BOM EId__c, SF ID>
			for(BOM__c b : exBOMs){
				exBOMsByEId.put(b.EId__c, b.Id);
			}

			Product2[] prodsToUpsert = new Product2[]{};
			// Upsert products to obtain SF ids
			for(Mdl.SfProduct r : recs){
				Product2 p = SyncUtils.mapProductFields(r);
				prodsToUpsert.add(p);
			}
			// UPSERT PRODUCTS
			Database.UpsertResult[] purs = Database.upsert(prodsToUpsert, Product2.SAPId__c.getDescribe().getSObjectField(), false);
            for(Integer i=0; i<purs.size();i++){
                if(!purs[i].isSuccess()){
                    errStr += 'ERROR: '+purs[i].getErrors()+'\n\n'+'UPSERTED PRODUCT: '+JSON.serializePretty(recs[i]+'\n\n');
                }
            }

			// Get also SF ids for currently inserted products
			Product2[] exProds = [SELECT Id,SAPId__c,(SELECT Id,SAPId__c,EId__c, BundleSAPId__c, BundleItemSAPId__c, Position__c, RowNumber__c FROM BOMs__r) FROM Product2 WHERE SAPId__c IN:exProdSAPIds];
			Map<String,Product2> exProdsBySAPId = new Map<String,Product2>(); // <Product SAPId__c, Product2>
			for(Product2 p : exProds){
				exProdsBySAPId.put(p.SAPId__c, p);
			}

			// Assign proper values
			BOM__c[] bomsToUpsert = new BOM__c[]{};
			BOM__c[] bomsToDelete = new BOM__c[]{};
			for(Integer i=0; i<prodsToUpsert.size(); i++){

				Product2 p = prodsToUpsert[i];
				Mdl.SfProduct r = recs[i];

				Map<String,BOM__c> bomsToDelMap = new Map<String,BOM__c>();
				Product2 tmpProd = exProdsBySAPId.get(r.SAPId);
				if(tmpProd != null && tmpProd.BOMs__r != null){
					for(BOM__c b : exProdsBySAPId.get(r.SAPId).BOMs__r){
						bomsToDelMap.put(b.EId__c,b);
					}
				}
				
				Mdl.SfBom[] sfBoms = (r.BOMs != null && r.BOMs.Records != null) ? r.BOMs.Records : new Mdl.SfBom[]{};
				for(Mdl.SfBom b : sfBoms){
					String bEId = r.SAPId+'-'+b.BundleItemSAPId+'-'+b.RowNumber;
					b.Id = exBOMsByEId.get(bEId);
					b.BundleId = p.Id;
					b.BundleItemId = exProdsBySAPId.get(b.BundleItemSAPId).Id; // Product (Material) must exist - it's logical premise, because it must be created in SAP and already synced to SF
					bomsToUpsert.add(SyncUtils.mapBomFields(b));
					bomsToDelMap.remove(bEId);
				}
				bomsToDelete.addAll(bomsToDelMap.values());
			}

			
			// UPSERT BOMs
			Database.UpsertResult[] burs = Database.upsert(bomsToUpsert, BOM__c.Id.getDescribe().getSObjectField(), false);
			for(Integer i=0; i<burs.size();i++){
				if(!burs[i].isSuccess()){
					errStr += 'ERROR: '+burs[i].getErrors()+'\n\n'+'UPSERTED BOM: '+JSON.serializePretty(bomsToUpsert[i]+'\n\n');
				}
			}
			// DELETE BOMs
			Database.DeleteResult[] bdrs = Database.delete(bomsToDelete, false);
			for(Integer i=0; i<bdrs.size();i++){
				if(!bdrs[i].isSuccess()){
					errStr += 'ERROR: '+bdrs[i].getErrors()+'\n\n'+'DELETED BOM: '+JSON.serializePretty(bomsToDelete[i]+'\n\n');
				}
			}
			// LOG SAVE RESULT PROBLEMS
			if(String.isNotEmpty(errStr)){
                stackTrace += '\n'+errStr;
                status = Cst.STATUS_WARNING;
			}
        }catch(Exception e){
            status = Cst.STATUS_ERROR;
            res.statusCode = 400;
            msg = e.getMessage() + e.getStackTraceString();
			stackTrace = e.getStackTraceString();
			res.responseBody = Blob.valueOf(msg+'\n'+stackTrace);
        }

		// Force set Response Status by settings
		if(stt.ForceStatusCode__c != null){ res.statusCode = (Integer)stt.ForceStatusCode__c; msg = 'FORCED STATUS CODE:\n'+msg; }

        SyncUtils.logServiceActivity(SVC_NAME, status, res.statusCode, msg, stackTrace, Hlp.getStringWithLength(body,32000));
        return;
	}
}