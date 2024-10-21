public without sharing class ProductBulkUpdateController {
    
    @AuraEnabled
	public static String auraGetInitData(){
		Mdl.PBUMdl pbuInit = new Mdl.PBUMdl();
		pbuInit.typePickVals = Hlp.getPickVals('Product2', 'Type__c');
		pbuInit.typePickVals.add(0, new Mdl.PickVal('0', '--None--'));
		pbuInit.specPickVals = Hlp.getPickVals('Product2', 'Specification__c');
		pbuInit.specPickVals.add(0, new Mdl.PickVal('0', '--None--'));
		pbuInit.prodFamilies = Hlp.getPickVals('Product2', 'Family');
		pbuInit.prodFamilies.add(0, new Mdl.PickVal('0', '--None--'));
		pbuInit.tmpRecordId = [SELECT Id FROM TemporaryRecord__c WHERE Name =:Cst.RFT_TMP_RECORD_NAME LIMIT 1].Id;
		pbuInit.guid = Hlp.NewGuid();

        // check if import is already running, if so, disable it
        ApexClass[] acs = [SELECT Id, Name from ApexClass WHERE Name IN: Cst.PROD_BATCH_NAMES_LIST];
        Id[] clsIds = new Id[]{};
        for(ApexClass ac : acs){
            clsIds.add(ac.Id);
        }
        System.debug('Apex class list:' + acs);


        AsyncApexJob[] aajs = [SELECT ApexClassId, JobType, Status FROM AsyncApexJob WHERE ApexClassId IN: clsIds AND Status NOT IN: Cst.ASYNC_JOB_FINISHED_STATUSES_LIST];
        System.debug('Async job list: ' + aajs);

        if(aajs.size() == 0){
            pbuInit.isImportEnabled = true;
        }
		return JSON.serialize(pbuInit);
	}

    @AuraEnabled
	public static String auraGetSearchResult(String sType, String sSpec, String sName){
        Mdl.PBUSearchMdl pbuSearch = new Mdl.PBUSearchMdl();
		String query = 'SELECT Id, Name, UnitCost__c, Specification__c, Type__c, BusinessName__c, BusinessNameEN__c, Description, ProductDescriptionCZ__c, ProductDescriptionEN__c, IsActive, IsDefault__c, UnitPriceCZK__c, UnitPriceEUR__c, UnitPriceUSD__c, Family FROM Product2';
		String shortQuery = '';
        String countQuery = 'SELECT count() FROM Product2';
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
            countQuery += ' WHERE ' + whereClause;
		}
		query += ' ORDER BY Name ASC';
        shortQuery += query;
		if(sName.length() < 2){
			shortQuery += ' LIMIT 50';
		}
		System.debug('Query ' + query);
        pbuSearch.query = JSON.serialize(Database.query(query));
        pbuSearch.shortQuery = JSON.serialize(Database.query(shortQuery));
        pbuSearch.recordCount = Database.countQuery(countQuery);
		return JSON.serialize(pbuSearch);
	}

    @AuraEnabled
    public static void auraSendExport(String exportData, String emailAddr){
        Product2[] dataToSend = (Product2[])JSON.deserialize(exportData, Product2[].class);
        Database.executeBatch(new ProductBulkGenerateBatch(dataToSend, emailAddr), 1000);
    }

    // After upload method
    @AuraEnabled
    public static String auraProductProcessing(String docId){
        Mdl.PBUSearchMdl pbuSearch = new Mdl.PBUSearchMdl();
        Product2[] shortProductList = new Product2[]{};
        System.debug('auraProductProcessing');
        String[] fileLines = new String[]{};
		ContentDocument[] cds = [SELECT LatestPublishedVersion.VersionData, Title FROM ContentDocument WHERE Id =: docId];
        String fileBody = cds[0].LatestPublishedVersion.VersionData.toString();
        // Integer indexPrev = 0;
        // Integer indexLast = 0;
        // while(indexLast != -1){
        //     indexPrev = indexLast;
        //     indexLast = fileBody.indexOf('"\n', indexPrev + 3);
        //     System.debug('Index Last' + indexLast);
        //     System.debug('Char ' + fileBody.substring(indexLast, indexLast+1));
        //     System.debug('Char ' + fileBody.substring(indexLast, indexLast+2));
        //     System.debug('Char ' + fileBody.substring(indexLast, indexLast+3));
        //     if(indexLast != -1){
        //         //skipList.add(indexLast);
        //         fileLines.add(fileBody.substring(0, indexLast+3));
        //     }else{
        //         fileLines.add(fileBody.substring(0, fileBody.length()));
        //     }
        // }

        String lineEnd;
        if(fileBody.contains('"\r\n')){
            lineEnd = '"\r\n';
        }else{
            lineEnd = '"\n';
        }
        pbuSearch.recordCount = fileBody.countMatches(lineEnd) - 1;
        
        Integer indexNL = 0;
        Integer indexR = 0;
        while(fileLines.size() <= 50){
            indexNL = fileBody.indexOf(lineEnd);
            // indexR = fileBody.indexOf('"\n\r');
            System.debug('Index NL' + indexNL);
            // System.debug('Index R' + indexR);
            // System.debug('FileBody' + fileBody);
            if(indexNL != -1){
                fileLines.add(fileBody.substring(0, indexNL));
                fileBody = fileBody.substring(indexNL + 3);
            }else{
                fileLines.add(fileBody.substring(0, fileBody.length()));
            }
        }
        System.debug('File Lines 1 ' + fileLines[0]);
        System.debug('File Lines 2 ' + fileLines[1]);
        System.debug('File Lines 3 ' + fileLines[2]);
        System.debug('File Lines 4 ' + fileLines[3]);

        Product2[] prods = new Product2[]{};
		for (Integer i = 1 ; i < fileLines.size()-1; i++){
            String[] inputValues = new String[]{};
            inputValues = fileLines[i].split('";"');
            System.debug('Input Values : ' + inputValues);

            if(auraGetStringValue(inputValues[0]).startsWith('01t')){
                Product2 prod = new Product2();
                System.debug('Id: ' + inputValues[0]);
                prod.Id = auraGetStringValue(inputValues[0]);
                prod.Name = auraGetStringValue(inputValues[1]);
                prod.Specification__c = (auraGetStringValue(inputValues[2]) == 'null') ? '' : inputValues[2];
                prod.BusinessName__c = (auraGetStringValue(inputValues[3]) == 'null') ? '' : inputValues[3];
                prod.BusinessNameEN__c = (auraGetStringValue(inputValues[4]) == 'null') ? '' : inputValues[4];
                prod.Description = (auraGetStringValue(inputValues[5]) == 'null') ? '' : inputValues[5];
                prod.ProductDescriptionCZ__c = (auraGetStringValue(inputValues[6]) == 'null') ? '' : inputValues[6];
                prod.ProductDescriptionEN__c = (auraGetStringValue(inputValues[7]) == 'null') ? '' : inputValues[7];
                prod.Family = (auraGetStringValue(inputValues[8]) == 'null') ? '' : inputValues[8];
                String unitCost = auraGetDacimalValue(auraGetStringValue(inputValues[9]));
                prod.UnitCost__c = Decimal.valueOf((unitCost == 'null') ? '0' : unitCost);
                String unitPriceCZK = auraGetDacimalValue(auraGetStringValue(inputValues[10]));
                prod.UnitPriceCZK__c = Decimal.valueOf((unitPriceCZK == 'null') ? '0' : unitPriceCZK);
                String unitPriceEUR = auraGetDacimalValue(auraGetStringValue(inputValues[11]));
                prod.UnitPriceEUR__c = Decimal.valueOf((unitPriceEUR == 'null') ? '0' : unitPriceEUR);
                String unitPriceUSD = auraGetDacimalValue(auraGetStringValue(inputValues[12]));
                prod.UnitPriceUSD__c = Decimal.valueOf((unitPriceUSD == 'null') ? '0' : unitPriceUSD);
                prod.IsActive = Boolean.valueOf(auraGetStringValue(inputValues[13]));
                prod.IsDefault__c = Boolean.valueOf(auraGetStringValue(inputValues[14]));
                prods.add(prod);
            }
        }
        pbuSearch.query = JSON.serialize(prods);
        pbuSearch.shortQuery = JSON.serialize(prods);
        return JSON.serialize(pbuSearch);
    }

    @AuraEnabled
    public static void auraUpdateProducts(String docId, String eAddr){
        // ContentDocument[] cds = [SELECT LatestPublishedVersion.VersionData, Title FROM ContentDocument WHERE Id =: docId];
        // String fileBody = cds[0].LatestPublishedVersion.VersionData.toString();
        // Integer[] endLines = new Integer[]{};
        // Integer indexNL = 0;
        // while(indexNL != -1){
        //     indexNL = fileBody.indexOf('"\n', indexNL + 2);
        //     System.debug('Index Last' + indexNL);
        //     if(indexNL != -1){
        //         endLines.add(indexNL);
        //     }else{
        //         endLines.add(fileBody.length());
        //     }
        // }
        // if(eAddr == null){
        //     eAddr = UserInfo.getUserEmail();
        // }
        // System.debug('Skip List ' + eAddr);
        // Database.executeBatch(new ProductBulkUpdateBatch(fileBody, endLines, eAddr), 100);
        Database.executeBatch(new ProductBulkGenerateBatch(docId, eAddr), 100);

    }

    public static String auraGetStringValue(String quotedValue){
        if(quotedValue.startsWith('"')){
            quotedValue = quotedValue.substring(1);
        }
        if(quotedValue.endsWith('"')){
            quotedValue = quotedValue.substring(0,quotedValue.length()-1);
        }
        return quotedValue;
    }

    @AuraEnabled
    public static void auraManualBackup(){
        Database.executeBatch(new ProductBulkGenerateBatch('', ''), 100);
    }

    public static String auraGetDacimalValue(String stringValue){
        if(stringValue.contains(',')){
            stringValue = stringValue.replace(',','.');
        }
        return stringValue;
    }
}