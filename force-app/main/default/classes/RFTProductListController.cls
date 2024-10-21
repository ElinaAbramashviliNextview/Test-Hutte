public without sharing class RFTProductListController  {

	@AuraEnabled
	public static String auraGetProds(String recordId){
		Mdl.RFTMdlList[] rftmdlS = new Mdl.RFTMdlList[]{};
		Product2[] prods = [SELECT Id, Name FROM Product2 WHERE RequestForTechnicianId__c =: recordId];
		for(Product2 prod : prods){
			Mdl.RFTMdlList rftmdl = new Mdl.RFTMdlList();
			rftmdl.id = prod.Id;
			rftmdl.name = prod.Name;
			rftmdlS.add(rftmdl);
		}
		System.debug('RFTMDL' + rftmdlS);
		return JSON.serialize(rftmdlS);

	}

	@AuraEnabled
	public static String auraDeleteProduct(String prodId, String recordId){
		BOM__c[] boms = [SELECT Id FROM BOM__c WHERE BundleId__c =: prodId];
		delete boms;
		ProductDescription__c[] prodDescs = [SELECT Id FROM ProductDescription__c WHERE ProductId__c =: prodId];
		delete prodDescs;

		ContentDocumentLink[] cdls = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: prodId];
		ContentDocument[] cds = new ContentDocument[]{};
		for(ContentDocumentLink cdl : cdls){
			ContentDocument cd = new ContentDocument(Id = cdl.ContentDocumentId);
			cds.add(cd);
		}
		delete cds;
		
		Product2[] prods = [SELECT Id FROM Product2 WHERE Id =: prodId];
		delete prods;
		return auraGetProds(recordId);
	}
}