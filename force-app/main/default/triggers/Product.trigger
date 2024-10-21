trigger Product on Product2(before update, after insert, after update) {
	/**
	  SUMMARY:
	  ----------------------------------------------------------------------------------------------------------------------
	  0. -----AI---        > Create pricebook entries
	  1. -----A-U--        > Update pricebook entries
	  2. -----A-U--        > Update related BOMs (UnitCosts and other values are recounted in the BOM trigger - Befor I/U)
	  3. B-U-------        > FORCE Sync to SAP if SyncStatus is "FORCE"
	  ----------------------------------------------------------------------------------------------------------------------
	*/

	
	// Get Standard Pricebook ID
	Id stdPbId = (Test.isRunningTest()) ? Test.getStandardPricebookId() :[SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1][0].Id;

	/* 0. */
	if (Trigger.isAfter && Trigger.isInsert) {
		PricebookEntry[] pbesToInsert = new PricebookEntry[] { };
		for (Product2 n : Trigger.new) {
			pbesToInsert.add(fillInPBE(n, null, Cst.CURR_CZK));
			pbesToInsert.add(fillInPBE(n, null, Cst.CURR_EUR));
			pbesToInsert.add(fillInPBE(n, null, Cst.CURR_USD));
		}
		System.debug('PriceBook Entry: ' + pbesToInsert);
		try{
			System.debug(pbesToInsert);

			// FUTURE CALLOUT NOT WORKING IN TEST
			if(!Test.isRunningTest()){
				Hlp.techPBEInsert(JSON.serialize(pbesToInsert));
			}else{
				insert pbesToInsert;
			}
		}catch(Exception e){
			System.debug('Message ' + e.getMessage());
			System.debug('Stack ' + e.getStackTraceString());
			System.debug('Cause ' + e.getCause());
		}
	}

	if (Trigger.isAfter && Trigger.isUpdate) {
		/* 1. */
		PricebookEntry[] exPbes = [SELECT Id, Product2Id, Pricebook2Id, CurrencyIsoCode, UnitPrice FROM PricebookEntry WHERE Product2Id IN :Trigger.newMap.keySet()];
		System.debug('exPBES' + exPbes);
		PricebookEntry[] pbesToUpdate = new PricebookEntry[] { };
		for (PricebookEntry pbe : exPbes) {
			pbesToUpdate.add(fillInPBE(Trigger.newMap.get(pbe.Product2Id), pbe.Id, pbe.CurrencyIsoCode));
		}
		System.debug('PriceBook Entry: ' + pbesToUpdate);
		// FUTURE CALLOUT NOT WORKING IN TEST
		if(!Test.isRunningTest() && !System.isBatch()){
			Hlp.techPBEUpdate(JSON.serialize(pbesToUpdate));
		}else{
			update pbesToUpdate;
		}
		/* 2. */
		BOM__c[] bomsToUpdate = new BOM__c[]{};
		for(BOM__c bom : [SELECT Id, IsRecalculate__c FROM BOM__c WHERE BundleItemId__c IN:Trigger.newMap.keySet()]){
			bom.IsRecalculate__c = true;
			bomsToUpdate.add(bom);
		}
		update bomsToUpdate;
	}

	if (Trigger.isBefore && Trigger.isUpdate) {
		/* 3. */
		Set<Id> syncProdIds = new Set<Id>();
		for(Product2 n : Trigger.new){
			if(n.SyncStatus__c == Cst.SYNC_STATUS_FORCE){
				syncProdIds.add(n.Id);
				n.SyncStatus__c = Cst.SYNC_STATUS_SYNCING;
			}
		}
		if(!syncProdIds.isEmpty()){
			System.enqueueJob(new Svc_ProductToSAP(syncProdIds, null));
		}
	}

	private static PricebookEntry fillInPBE(Product2 p, Id pbeId, String pbeCurr) {
		PricebookEntry r = new PricebookEntry();
		r.Id = pbeId;
		if (pbeId == null) {
			r.Pricebook2Id = stdPbId; // Standard Pricebook (set only for insert - not updatable)
			r.Product2Id = p.Id;
			r.CurrencyIsoCode = pbeCurr;
			r.IsActive = true;
			r.UseStandardPrice = false;
		}
		r.IsActive = p.IsActive;
		// Set price
		if (pbeCurr == Cst.CURR_CZK) {
			r.UnitPrice = (p.UnitPriceCZK__c != null) ? p.UnitPriceCZK__c : 0;
		} else if (pbeCurr == Cst.CURR_EUR) {
			r.UnitPrice = (p.UnitPriceEUR__c != null) ? p.UnitPriceEUR__c : 0;
		} else if (pbeCurr == Cst.CURR_USD) {
			r.UnitPrice = (p.UnitPriceUSD__c != null) ? p.UnitPriceUSD__c : 0;
		}
		return r;
	}
}