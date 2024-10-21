public without sharing class NewProductTechniciansController  {

	@AuraEnabled
	public static String auraGetInitData(){
		Mdl.RFTInitMdl rftInit = new Mdl.RFTInitMdl();
		rftInit.typePickVals = Hlp.getPickVals('Product2', 'Type__c');
		rftInit.typePickVals.add(0, new Mdl.PickVal('0', '--None--'));
		rftInit.specPickVals = Hlp.getPickVals('Product2', 'Specification__c');
		rftInit.specPickVals.add(0, new Mdl.PickVal('0', '--None--'));
		rftInit.qomPickVals = Hlp.getPickVals('Product2', 'QuantityUnitOfMeasure');
		rftInit.qomPickVals.add(0, new Mdl.PickVal('0', '--None--'));
		rftInit.currncyPickVals = Hlp.getPickVals('Product2', 'CurrencyIsoCode');
		rftInit.currncyPickVals.add(0, new Mdl.PickVal('0', '--None--'));
		rftInit.prodFamilies = Hlp.getPickVals('Product2', 'Family');
		rftInit.prodFamilies.add(0, new Mdl.PickVal('0', '--None--'));
		rftInit.tmpRecordId = [SELECT Id FROM TemporaryRecord__c WHERE Name =:Cst.RFT_TMP_RECORD_NAME LIMIT 1].Id;
		rftInit.guid = Hlp.NewGuid();
		System.debug('typePickVals'+rftInit.typePickVals);
		return JSON.serialize(rftInit);
	}

	@AuraEnabled
	public static String auraGetProductDetail(String prodId){
		Mdl.RFTMdl rftm = new Mdl.RFTMdl();
		if(prodId != null){
			rftm.prod = [SELECT Name, Type__c, CurrencyIsoCode, QuantityUnitOfMeasure, Description, BusinessName__c, BusinessNameEN__c, ProductDescriptionCZ__c, ProductDescriptionEN__c, UnitCost__c, Family FROM Product2 WHERE Id =: prodId ORDER BY Name DESC LIMIT 1];
			rftm.boms = [SELECT Name, BundleId__c, BundleItemId__r.Name, BundleItemId__r.ProductCode, BundleItemId__r.QuantityUnitOfMeasure, Quantity__c, BundleItemId__r.UnitCost__c, Position__c, UnitCost__c, QuantityUnitOfMeasure__c FROM BOM__c WHERE BundleId__c =: prodId];		
			rftm.prodDescs = [SELECT Name, TitleCZ__c, TitleEN__c, DescriptionCZ__c, DescriptionEN__c, RowNumber__c FROM ProductDescription__c WHERE ProductId__c =: prodId];

			Mdl.ProductAttachmentsModel[] pAttM = new Mdl.ProductAttachmentsModel[]{};
			Set<Id> cdIds = new Set<Id>();
			ContentDocumentLink[] cdls = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: prodId];
			for(ContentDocumentLink cdl : cdls){
				cdIds.add(cdl.ContentDocumentId);
			}
			ContentDocument[] cds = [SELECT Title, Id, FileType, LatestPublishedVersionId FROM ContentDocument WHERE Id IN: cdIds]; 
			if(!cds.isEmpty()){
                for(ContentDocument cd : cds){
                    Mdl.ProductAttachmentsModel pam = new Mdl.ProductAttachmentsModel();
                    pam.id = cd.Id;
                    String onlyName = cd.Title;
                    pam.shortName = Hlp.getFormatedSubstring(onlyName, 20);
                    pam.fullName = onlyName + '.' + cd.FileType.toLowerCase();
                    pam.suffix = cd.FileType.toLowerCase();
                    pam.isAttached = false;
                    pam.sendName = Hlp.getFormatedSubstring(onlyName, 15);
                    pam.attachLink = '/sfc/servlet.shepherd/version/download/' + cd.LatestPublishedVersionId;
                    pAttM.add(pam);
                }
            }
			rftm.pAttchMdl = pAttM;
		}else{
			rftm.prod = new Product2(Name = '', Type__c = '0', CurrencyIsoCode = 'CZK', QuantityUnitOfMeasure = '0', Description = '');
		}
		System.debug('RFTModel ' + rftm);
		return JSON.serialize(rftm);
	}

	@AuraEnabled
	public static String auraGetSearchResult(String sType, String sSpec, String sName){

		String query = 'SELECT Name, UnitCost__c, ProductCode, Specification__c, Type__c, QuantityUnitOfMeasure FROM Product2';
		String whereClause = '';

		if(sType != '0'){whereClause += 'Type__c = \'' + sType + '\'';}

		if(sSpec != '0'){
			if(!String.isEmpty(whereClause)){
				whereClause += ' AND Specification__c = \'' + sSpec + '\'';
			}else{
				whereClause += 'Specification__c = \'' + sSpec + '\'';
			}
		}

		if(sName != ''){ 
			System.debug('Name length: ' + sName.length());
			if(!String.isEmpty(whereClause)){
				whereClause += ' AND Name LIKE \'%' + sName + '%\'';
			}else{
				whereClause += 'Name LIKE \'%' + sName + '%\'';
			}
		}

		if(whereClause != ''){
			query += ' WHERE ' + whereClause;
		}
		query += ' ORDER BY Name ASC';
		if(sName.length() < 2){
			query += ' LIMIT 50';
		}
		System.debug('Query ' + query);
		return JSON.serialize(Database.query(query));
	}

	@AuraEnabled
	public static void auraSaveBundle(String rftModel, String bomsToDel, String pdToDel, String recordId, String guid){
		Mdl.RFTMdl rftMdl = (Mdl.RFTMdl)JSON.deserialize(rftModel, Mdl.RFTMdl.class);
		BOM__c[] bomsToDelete = (BOM__c[])JSON.deserialize(bomsToDel, BOM__c[].class);
		ProductDescription__c[] pdsToDelete = (ProductDescription__c[])JSON.deserialize(pdToDel, ProductDescription__c[].class);

		System.debug('RFTMdl ' + rftMdl.prod);

		RequestForTechnician__c req = [SELECT QuoteCurrency__c FROM RequestForTechnician__c WHERE Id =: recordId];

		Decimal totalBOMUnitCost = 0;
		if(rftMdl.boms.size() > 0){
			for(BOM__c bom : rftMdl.boms){
				totalBOMUnitCost += bom.BundleItemId__r.UnitCost__c * bom.Quantity__c;
			}
		}

		rftMdl.prod.RequestForTechnicianId__c = recordId;
		rftMdl.prod.IsActive = true;
		rftMdl.prod.IsDefault__c = true;
		rftMdl.prod.UnitPriceCZK__c = totalBOMUnitCost * 4.5;
		rftMdl.prod.UnitPriceCZK__c = rftMdl.prod.UnitPriceCZK__c.setScale(0);
		CurrencyType ctEur = [SELECT ConversionRate,IsActive,IsoCode FROM CurrencyType WHERE IsoCode = 'EUR' AND IsActive = true];
		rftMdl.prod.UnitPriceEUR__c = totalBOMUnitCost * ctEur.ConversionRate * 4.5;
		rftMdl.prod.UnitPriceEUR__c = rftMdl.prod.UnitPriceEUR__c.setScale(0);
		CurrencyType ctUsd = [SELECT ConversionRate,IsActive,IsoCode FROM CurrencyType WHERE IsoCode = 'USD' AND IsActive = true];
		rftMdl.prod.UnitPriceUSD__c = totalBOMUnitCost * ctUsd.ConversionRate * 4.5;
		rftMdl.prod.UnitPriceUSD__c = rftMdl.prod.UnitPriceUSD__c.setScale(0);

		upsert rftMdl.prod;

		for(BOM__c bom : rftMdl.boms){
			bom.BundleId__c = rftMdl.prod.Id;
		}
		upsert rftMdl.boms;

		for(ProductDescription__c pd: rftMdl.prodDescs){
			pd.Name = pd.TitleCZ__c;
			pd.ProductId__c = rftMdl.prod.Id;
		}
		upsert rftMdl.prodDescs;

		delete bomsToDelete;
		delete pdsToDelete;


		Boolean isInsertSuccess = true;
		ContentVersion[] cvs = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE IsLatest = true AND RefId__c =: guid];

		Set<String> cdIds = new Set<String>();
		if(cvs.size() > 0){
	        for(ContentVersion cv : cvs){
	            cdIds.add(cv.ContentDocumentId);
	        }				
		}
		String tmpRecordId = [SELECT Id FROM TemporaryRecord__c WHERE Name =:Cst.RFT_TMP_RECORD_NAME LIMIT 1].Id;
        if(!cdIds.isEmpty()){
			System.debug('Content Document Ids ' + cdIds);
            ContentDocumentLink[] cdlToDel = [SELECT Id,ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN :cdIds AND LinkedEntityId =: tmpRecordId];
            ContentDocumentLink[] cdlToInsert = new List<ContentDocumentLink>();
                
            // Create ContentDomumentLink to FormInquory for all files with association with System Lead
            for(ContentDocumentLink cdl : cdlToDel){
                // cerate CDL to FormInquiry
                ContentDocumentLink tmpCdl = new ContentDocumentLink();
                tmpCdl.ContentDocumentId = cdl.ContentDocumentId;
                tmpCdl.LinkedEntityId = rftMdl.prod.Id;
                tmpCdl.ShareType = 'V';
                cdlToInsert.add(tmpCdl);
            }
            System.debug('New CDLs: ' + cdlToInsert);
            Database.SaveResult[] cdlResult = Database.insert(cdlToInsert, true);

            // check if insert was succesfull
            for(Database.SaveResult sr : cdlResult){
                if(!sr.isSuccess()){
                    isInsertSuccess = false;
                }
            }

            // delete ContentDocumentLink to System RFT after succesfull link to Product
            if(isInsertSuccess){
                delete cdlToDel;
            }
        }
	}

	@AuraEnabled
	public static String auraUploadFile(String[] docIds, String guid){
		ContentVersion[] cvs = new ContentVersion[]{};
		Mdl.ProductAttachmentsModel[] pAttM = new Mdl.ProductAttachmentsModel[]{};

		ContentDocument[] cds = [SELECT LatestPublishedVersionId, Title FROM ContentDocument WHERE Id IN: docIds];
		System.debug('ContentDocument' + cds);
		if(cds.size() > 0){
			for(ContentDocument cd : cds){	
				ContentVersion cv = new ContentVersion(Id = cd.LatestPublishedVersionId, RefId__c = guid);
				cvs.add(cv);

				// Generate View/Download Link
				Mdl.ProductAttachmentsModel pam = new Mdl.ProductAttachmentsModel();
                pam.id = cd.Id;
                pam.name = cd.Title;
                pam.attachLink = '/portal/sfc/servlet.shepherd/version/download/' + cd.LatestPublishedVersionId;
                pAttM.add(pam);
			}
			update cvs;
		}
		System.debug('Prod Attachments'+ pAttM);
		return JSON.serialize(pAttM);
	}

	@AuraEnabled
	public static void auraRemoveContentDocument(String attachId){
		ContentDocument cd = new ContentDocument(Id = attachId);
		delete cd;
	}
}