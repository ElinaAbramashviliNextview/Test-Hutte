public class Svc_ProductToSAP implements Queueable, Database.AllowsCallouts {
	private static String SVC_NAME = 'ProductToSAP';
	
	public Set<Id> recIds{get;set;}
	public Set<Id> ordrIds{get;set;}

	public Svc_ProductToSAP(Set<Id> rIds, Set<Id> oIds){
		recIds = rIds;
		ordrIds = oIds;
	}

    public void execute(QueueableContext qc) {
		syncToSAP(recIds, ordrIds);
	}

	public static void syncToSAP(Set<Id> recIds, Set<Id> orderIds){
		SyncServiceSettings__c stt = SyncServiceSettings__c.getValues(SVC_NAME);
        if(stt.DisableSync__c){ SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_ERROR, 503, 'ERROR: Service is disabled'); return; }
		try{
			//SyncUtils.validateAccess(SVC_NAME);
    		Set<Id> chldRecIds = new Set<Id>();
			Product2[] prods = [SELECT
								BusinessNameEN__c,
								Description,
								Family, // V, Výrobek | M, Materiál | P, Polotovar | Z, Zboží | S, Služby
										// Skupina artiklů. Dle počátečního písmena skupiny artiklů lze rozlišit,
										// o kterou kategorii se jedná. Například M-Dřevo je materiál. V-Výrobek je pak výrobek, atd.
								Id,
								IsActive,
								Name,
								ProductCode, // Kód artiklu v Salesforce (Pro nově vzniklé výrobky v SF)
								QuantityUnitOfMeasure,
								Specification__c, // Multiselect picklist = hodnota se přenáší do ItemAttributes
								Type__c, // Typ produktu (Standard Bundle, Product, Custom Bundle)
								UnitCost__c, // Nákladová cena za kus. Vždy v CZK (currency ISO code).
								UnitPriceCZK__c, // Prodejní cena za kus v CZK.	Prodejní cena z ceníku 1
								UnitPriceUSD__c, // Prodejní cena za kus v USD.	Prodejní cena z ceníku 1 - doplňková měna 1
								UnitPriceEUR__c, // Prodejní cena za kus v EUR.	Prodejní cena z ceníku 1 - doplňková měna 2
								SAPId__c,
								(SELECT
									BundleId__c, 
									BundleSAPId__c, // Kód artiklu ze SAP - (nadřazený výrobek)
									BundleItemId__c,
									BundleItemSAPId__c, // Kód artiklu ze SAP - (/materiál)
									Id,
									//Name,	
									Quantity__c, // Množství.	Množství materiálu na 1KS nadřazeného výrobku
									QuantityUnitOfMeasure__c, // MJ.	Skladová měrná jednotka
									RowNumber__c, // Číslo řádku v kusovníku.	Číslo řádku v kusovníku
									Type__c, // Např. MAX-MATERIAL atd...
									Position__c // Označení pozice výroby - text (čalouníci, montáž, 1, 2 atd. - může být označeno názvem nebo číslem)
									FROM BOMs__r)
								FROM Product2 WHERE Id IN:recIds];

			for(Product2 chP : prods){
				for(BOM__c bom : chP.BOMs__r){
					if(!recIds.contains(bom.BundleItemId__c)){
						chldRecIds.add(bom.BundleItemId__c);
					}
				}
			}
			Product2[] recs = [SELECT Description, Family, Id, IsActive, Name, ProductCode, QuantityUnitOfMeasure, Specification__c, Type__c, UnitCost__c, UnitPriceCZK__c, UnitPriceUSD__c, UnitPriceEUR__c, SAPId__c
								FROM Product2 WHERE Id IN:chldRecIds];
			recs.addAll(prods);

			// Convert Specification__c to SAP format
			for(Product2 p : recs){
				p.Specification__c = SyncUtils.productSpecificationToItemAttributes(p.Specification__c);
			}

			String dataStr = JSON.serialize(recs, false);
			HttpResponse res = SyncUtils.sendData(SVC_NAME, dataStr);
			String respBody = res.getBody();
			String status;
			if(res.getStatusCode() == 200){
				status = Cst.STATUS_SUCCESS;
				SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_SUCCESS, res.getStatusCode(), 'SUCCESS: products synced ('+String.join(new List<Id>(recIds),', ')+')', null, dataStr, respBody);
			}else{
				status = Cst.STATUS_ERROR;
				SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_ERROR, res.getStatusCode(), 'ERROR - something wents wrong: ' + res.getStatus(), res.getBody(), dataStr, respBody);
			}
		
			Map<Id,String> respMap = new Map<Id,String>();
			try{
				Mdl.SAPResponse[] respRecs = (Mdl.SAPResponse[])JSON.deserialize(SyncUtils.getValidJsonForCustomModel(respBody), Mdl.SAPResponse[].class);
				for(Mdl.SAPResponse r : respRecs){
					respMap.put(r.Id, r.SAPId);
				}
			}catch(Exception ex){
				status = Cst.STATUS_WARNING;
				SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_WARNING, res.getStatusCode(), 'WARNING - response was not parsed: '+ex.getMessage(), ex.getStackTraceString(), null, respBody);
			}

			// Set result recs
			Product2[] prodsToUpdate = new Product2[]{};
			for(Product2 p : recs){
				Product2 np = new Product2();
				np.Id = p.Id;
				np.SyncStatus__c = status;
				String sapId = respMap.get(p.Id);
				if(sapId != null){
					np.SAPID__c = sapId;
				}
				prodsToUpdate.add(np);
			}
			update prodsToUpdate;
			// Also set related Orders for Sync
			if(orderIds != null && !orderIds.isEmpty()){
				System.enqueueJob(new Svc_OrderToSAP(orderIds)); // If success and Ids defined - call next job
			}
		}catch(Exception e){
			SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_ERROR, 0, e.getMessage(), e.getStackTraceString());
		}
	}

    public static void sendData(Set<Id> recIds, Set<Id> orderIds){

	}
}