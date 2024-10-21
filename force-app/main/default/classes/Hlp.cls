public without sharing class Hlp {

	
	//===================================================================================================
	// MISC - MISC - MISC - MISC - MISC - MISC - MISC - MISC - MISC - MISC - MISC - MISC - MISC - MISC - 
	//===================================================================================================

	/// Returns string of specific length
	public static String getStringWithLength(String str, Integer length){
		if(String.isEmpty(str)){ return ''; }
		return (str.length() > length) ? str.substring(0, length) : str;
	}

	private static Id pvtStdPbId;
	public static Id getStandardPriceBookId(){
		if(pvtStdPbId == null){
			if(Test.isRunningTest()){
				pvtStdPbId = Test.getStandardPricebookId();
			}else{
				Pricebook2 spb = [SELECT Id FROM Pricebook2 WHERE IsActive = true AND IsStandard = true LIMIT 1][0]; // Standard PB must be defined
				pvtStdPbId = spb.Id;
			}
		}
		return pvtStdPbId;
	}

	/* Generate Guid
	***************************************************************/
	public static String NewGuid() {
		Blob b = Crypto.GenerateAESKey(128);
		String h = EncodingUtil.ConvertTohex(b);
		String guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
		return guid;
	}

	public static String getFormatedSubstring(String str, Integer length){
		String res = '';
		if(str != null){
			res = (str.length() > length) ? str.substring(0,length)+'...' : str;
		}
		return res;
	}

	//===================================================================================================
	// OPPORTUNITY - OPPORTUNITY - OPPORTUNITY - OPPORTUNITY - OPPORTUNITY - OPPORTUNITY - OPPORTUNITY - 
	//===================================================================================================
		@Future(callout=true)
		public static void afterOppInsert(Id oppId){
			Opportunity o = [SELECT Id, Name, OpportunityNo__c, NumericalSeries__c FROM Opportunity WHERE Id =: oppId];
			System.debug('afterOppInsert()');
			// Create google drive folder
			GoogleDriveService.createOppFolderStructure(o);
			// GoogleDriveService.createFolder(o.Name, o);
		}

		@future
		public static void handleOppHierarchyClose(Set<Id> projectClosedLostOppIds, Set<Id> childClosedWonOppIds){
			// project opportunity closed lost, close all child opps and set amount avg to parent 
			if(!projectClosedLostOppIds.isEmpty()){
				Opportunity[] childOpps = [SELECT Id, ParentOpportunityId__c, StageName, Amount, CurrencyIsoCode, CloseDate
					FROM Opportunity 
					WHERE ParentOpportunityId__c IN: projectClosedLostOppIds];
				// preapre map
				Map<Id, Opportunity[]> childOppsByParentIdMap = new Map<Id, Opportunity[]>{};
				for(Opportunity o : childOpps){
					Opportunity[] tmp = childOppsByParentIdMap.get(o.ParentOpportunityId__c);
					if(tmp == null){
						tmp = new Opportunity[]{};
						childOppsByParentIdMap.put(o.ParentOpportunityId__c, tmp);
					}
					tmp.add(o);
				}

				// count amount avg and preapre opps to update
				Opportunity[] oppsToUpdate =  new Opportunity[]{};
				for(Id parentOppId : childOppsByParentIdMap.keySet()){
					Opportunity parent = new Opportunity(Id = parentOppId);
					Opportunity[] childs = childOppsByParentIdMap.get(parentOppId);
					Integer childsCount = childs.size();
					Decimal childsAmountSum = 0;

					for(Opportunity child : childs){
						childsAmountSum += Svc_OppCSVExport.getConvertedCZKValue(child.Amount, child.CurrencyIsoCode, child.CloseDate);
						child.StageName = 'Closed Lost';
						oppsToUpdate.add(child);
					}

					if(childsCount > 0){
						parent.Amount = childsAmountSum / childsCount;
						parent.StageName = 'Closed Lost';
						parent.CurrencyIsoCode = 'CZK';
						oppsToUpdate.add(parent);
					}

					if(!oppsToUpdate.isEmpty()){
						update oppsToUpdate;
					}
				}
			}

			// child opp set closed won, set other childs as closed lost
			if(!childClosedWonOppIds.isEmpty()){
				// get won opps and prepare parentIDs
				Opportunity[] wonOpps = [SELECT Id, AccountId, StageName, ParentOpportunityId__c, Amount, CurrencyIsoCode, CloseDate, OrderDueDate__c, ProformaPercent__c, ProformaIssuedDatePlan__c, ProformaPaidDatePlan__c, RealizationStartDate__c, RealizationEndDate__c, Street__c, PostalCode__c, City__c, Country__c
					FROM Opportunity 
					WHERE Id IN: childClosedWonOppIds];

				Set<Id> parentIds = new Set<Id>();
				for(Opportunity o : wonOpps){
					parentIds.add(o.ParentOpportunityId__c);
				}

				// get childOpps and ParentOpps
				Opportunity[] childOpps = [SELECT Id, AccountId, StageName, ParentOpportunityId__c, Amount, CurrencyIsoCode, CloseDate
				FROM Opportunity 
				WHERE ParentOpportunityId__c IN: parentIds AND ID NOT IN: childClosedWonOppIds];

				Map<Id, Opportunity> parentOppsMap = new Map<Id,Opportunity>([SELECT Id, ParentOpportunityId__c, StageName, Amount, CurrencyIsoCode, CloseDate, OrderDueDate__c, ProformaPercent__c, ProformaIssuedDatePlan__c, ProformaPaidDatePlan__c, RealizationStartDate__c, RealizationEndDate__c, Street__c, PostalCode__c, City__c, Country__c
				FROM Opportunity 
				WHERE Id IN: parentIds]);

				// set childs as closed lost and update parents
				Opportunity[] oppsToUpdate = new Opportunity[]{};
				for(Opportunity o : childOpps){
					o.StageName = 'Closed Lost';
					oppsToUpdate.add(o);
				}
				for(Opportunity o : wonOpps){
					Opportunity parent = parentOppsMap.get(o.ParentOpportunityId__c);
					if(parent != null){
						parent.AccountId = o.AccountId;
						parent.CurrencyIsoCode = o.CurrencyIsoCode;
						parent.Amount = o.Amount;
						parent.StageName = o.StageName;
                        parent.CloseDate = o.CloseDate;
						parent.IsClosedWonApexSet__c = true;
						parent.OrderDueDate__c = o.OrderDueDate__c;
						parent.ProformaPercent__c = o.ProformaPercent__c;
						parent.ProformaIssuedDatePlan__c = o.ProformaIssuedDatePlan__c;
						parent.ProformaPaidDatePlan__c = o.ProformaPaidDatePlan__c;
						parent.RealizationStartDate__c = o.RealizationStartDate__c;
						parent.RealizationEndDate__c = o.RealizationEndDate__c;
						parent.Street__c = o.Street__c;
						parent.PostalCode__c = o.PostalCode__c;
						parent.City__c = o.City__c;
						Parent.Country__c = o.Country__c;
						oppsToUpdate.add(parent);
					}
				}

				if(!oppsToUpdate.isEmpty()){
					update oppsToUpdate;
				}

			}
		}
		
	//===================================================================================================
	// QUOTE - QUOTE - QUOTE - QUOTE - QUOTE - QUOTE - QUOTE - QUOTE - QUOTE - QUOTE - QUOTE - QUOTE - QU
	//===================================================================================================
	
	// Set Project Amount by current opportunity
	// - handle if it's called from future or batch
	// -------------------------------------------------------------------------------------
	public static void setProjectAmountByCurrentOpportunity(Map<Id,Id> oppIdsMap){
		if(oppIdsMap.isEmpty()){return;}
		if(System.isFuture() || System.isBatch()){
			setProjectAmountByOpp(oppIdsMap);
		}else {
			setProjectAmountByOppFuture(oppIdsMap);	
		}
	}

	@future
	private static void setProjectAmountByOppFuture(Map<Id,Id> oppIdsMap){
		setProjectAmountByOpp(oppIdsMap);
	}
	
	private static void setProjectAmountByOpp(Map<Id,Id> oppIdsMap){
		Opportunity[] pjcts = new Opportunity[]{};
		for(Opportunity opp : [SELECT Id, Amount, ParentOpportunityId__c FROM Opportunity WHERE Id IN:oppIdsMap.values()]){
			pjcts.add(new Opportunity(Id=opp.ParentOpportunityId__c, Amount=opp.Amount));
		}
		update pjcts;
	}
	// -------------------------------------------------------------------------------------


	public static void syncQuoteToOpportunity(Id qteId, Id oppId){
		Map<Id,Id> m = new Map<Id,Id>();
		m.put(qteId,oppId);
		syncQuoteToOpportunity(m);
	}

	@future
	public static void syncQuoteToOpportunity(Map<Id,Id> quoteOppIds){
		Opportunity[] oppsToUpdate = new Opportunity[]{};
		for(Id qId : quoteOppIds.keySet()){
			oppsToUpdate.add(new Opportunity(Id=quoteOppIds.get(qId),SyncedQuoteId=qId));
		}
		update oppsToUpdate;
	}

	//===================================================================================================
	// PRODUCT - PRODUCT - PRODUCT - PRODUCT - PRODUCT - PRODUCT - PRODUCT - PRODUCT - PRODUCT - PRODUCT
	//===================================================================================================

	@future(callout=true)
	public static void techPBEInsert(String pbesJson){
		TechnicianPricebookEntrySettings__c tpbes = TechnicianPricebookEntrySettings__c.getValues('default');
		if(tpbes == null || tpbes.SessionId__c == null){
			return;
		}
		System.debug('PBEs String: ' + pbesJson);
		String body = '{"records" :[';
		PricebookEntry[] pbes = (PricebookEntry[])JSON.deserialize(pbesJson, PricebookEntry[].class);
		for(Integer i = 0; i < pbes.size(); i++){
			body += fillMdlPBEInsert(pbes[i], i);
		}
		body = body.removeEnd(',');
		body += ']}';
		System.debug('Request Body: ' + body);

		Http h = new Http();
		HttpRequest req = new HttpRequest();
		req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v47.0/composite/tree/PricebookEntry/');
		req.setMethod('POST');
		req.setBody(body);
		req.setHeader('Authorization', 'OAuth ' + tpbes.SessionId__c);
		req.setHeader('Content-Type', 'application/json');
		HttpResponse res = h.send(req);
		System.debug('Pbe result: ' + res.getStatusCode() + ', ' + res.getBody());
	}
	
	public static String fillMdlPBEInsert(PricebookEntry pbe, Integer order){
		return '{"attributes" : {"type" : "PricebookEntry", "referenceId" : "ref'+ order +'"}, "Pricebook2Id" : "'+pbe.Pricebook2Id+'", "Product2Id" : "'+pbe.Product2Id+'", "CurrencyIsoCode" : "'+pbe.CurrencyIsoCode+'", "IsActive" : "'+pbe.IsActive+'", "UseStandardPrice" : "'+false+'", "UnitPrice" : "'+pbe.UnitPrice+'"},';
	}

	public static String fillMdlPBEUpdate(PricebookEntry pbe, Integer order){
		return '{"attributes" : {"type" : "PricebookEntry", "referenceId" : "ref'+ order +'"}, "Id" : "'+pbe.Id+'", "UnitPrice" : "'+pbe.UnitPrice+'"},';
	}
	
	@future(callout=true)
	public static void techPBEUpdate(String pbesJson){
		TechnicianPricebookEntrySettings__c tpbes = TechnicianPricebookEntrySettings__c.getValues('default');
		if(tpbes == null || tpbes.SessionId__c == null){
			return;
		}
		System.debug('PBEs String: ' + pbesJson);
		String body = '{"records" :[';
		PricebookEntry[] pbes = (PricebookEntry[])JSON.deserialize(pbesJson, PricebookEntry[].class);
		for(Integer i = 0; i < pbes.size(); i++){
			body += fillMdlPBEUpdate(pbes[i], i);
		}
		body = body.removeEnd(',');
		body += ']}';
		System.debug('Request Body: ' + body);

		Http h = new Http();
		HttpRequest req = new HttpRequest();
		req.setEndpoint(URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v47.0/composite/sObjects');
		req.setMethod('PATCH');
		req.setBody(body);
		req.setHeader('Authorization', 'OAuth ' + tpbes.SessionId__c);
		req.setHeader('Content-Type', 'application/json');
		HttpResponse res = h.send(req);
		System.debug('Pbe result: ' + res.getStatusCode() + ', ' + res.getBody());
	}

	//===================================================================================================
	// ORDER - ORDER - ORDER - ORDER - ORDER - ORDER - ORDER - ORDER - ORDER - ORDER - ORDER - ORDER - OR
	//===================================================================================================
		public static void createOrderAndSyncProducts(Set<Id> recIds){
			// Get primary quotes data
			Quote[] qts = [SELECT Id,AccountId,ContactId,CurrencyIsoCode,Description,Discount,Name,OpportunityId,Opportunity.Name,OwnerId,OwnerSAPId__c,Phone,QuoteDiscount__c,Subtotal,TotalPrice,
									BillingName,BillingCity,BillingStreet,BillingPostalCode,BillingStateCode,BillingCountryCode,BillingCountry,
									ShippingName,ShippingCity,ShippingStreet,ShippingPostalCode,ShippingStateCode,ShippingCountryCode,ShippingCountry,
									Opportunity.OrderDueDate__c,Opportunity.RealizationStartDate__c, Opportunity.RealizationEndDate__c, Opportunity.OnSiteContactId__c,
									(SELECT Id,CurrencyIsoCode,Description,Discount,IsDefault__c,LineNumber,ListPrice,OpportunityLineItemId,PricebookEntryId,Product2Id,Product2.SAPId__c,ProductDescriptionCZ__c,ProductDescriptionEN__c,ProductFamily__c,ProductName__c,Quantity,QuoteId,ServiceDate,SortOrder,Subtotal,TotalPrice,UnitPrice
										FROM QuoteLineItems)
								FROM Quote WHERE Id IN:recIds];

			Set<Id> prodIds = new Set<Id>();
			for(Quote q : qts){
				for(QuoteLineItem qli : q.QuoteLineItems){
					prodIds.add(qli.Product2Id);
				}
			}
			
			// Create Order from Opportunity > Synced Quote
			Order__c[] ordsToInsert = new Order__c[]{};
			for(Quote q : qts){
				Order__c no = new Order__c();
				no.AccountId__c = q.AccountId;
				no.BillingAddressTxt__c = createAddressTxt(q.BillingStreet, q.BillingCity, q.BillingPostalCode, q.BillingCountry);
				no.CurrencyIsoCode = q.CurrencyIsoCode;
				no.Description__c = q.Description;
				no.DueDate__c = q.Opportunity.OrderDueDate__c;
				no.RealizationStartDate__c = q.Opportunity.RealizationStartDate__c;
				no.RealizationEndDate__c = q.Opportunity.RealizationEndDate__c ;
				no.Name = q.Opportunity.Name;
				no.OpportunityId__c = q.OpportunityId;
				no.OwnerId = q.OwnerId;
				no.OwnerSAPId__c = q.OwnerSAPId__c;
				no.PrimaryContactId__c = q.ContactId;
				no.OnSiteContactId__c = q.Opportunity.OnSiteContactId__c;
				no.QuoteId__c = q.Id;
				no.SAPOrderStatus__c = Cst.ORDER_SAP_STATUS_I; // From SF it's always set to "I"
				no.ShippingAddressTxt__c = createAddressTxt(q.ShippingStreet, q.ShippingCity, q.ShippingPostalCode, q.ShippingCountry);
				ordsToInsert.add(no);
			}
			insert ordsToInsert;

			Set<Id> ordIds = new Set<Id>();
			OrderLineItem__c[] olisToInsert = new OrderLineItem__c[]{};
			for(Integer i=0;i<ordsToInsert.size();i++){
				Quote q = qts[i];
				Order__c o = ordsToInsert[i];
				ordIds.add(o.Id); // Add to set ids for calling the sync method
				System.debug('Order Id: '+o.Id);
				Integer counter = 0;
				for(QuoteLineItem qli : q.QuoteLineItems){
					OrderLineItem__c oli = new OrderLineItem__c();
					oli.QuoteLineItemId__c = qli.Id;
					oli.IsDefault__c = qli.IsDefault__c;
					oli.CurrencyIsoCode = qli.CurrencyIsoCode;
					oli.Description__c = qli.Description;
					oli.Discount__c = qli.Discount;
					oli.ListPrice__c = qli.ListPrice;
					oli.LineNum__c = counter;
					oli.Name = qli.ProductName__c;
					oli.OrderId__c = o.Id;
					oli.ProductId__c = qli.Product2Id;
					oli.Quantity__c = qli.Quantity;
					oli.Subtotal__c = qli.Subtotal;
					oli.TotalPrice__c = qli.TotalPrice;
					oli.UnitPrice__c = qli.UnitPrice;
					olisToInsert.add(oli);
					counter++;
				}
			}
			insert olisToInsert;

			// Sync Products to SAP
			Map<Id,Product2> pMap = new Map<Id,Product2>([SELECT Id, SyncStatus__c, SAPId__c FROM Product2 WHERE Id IN:prodIds AND (SAPId__c=null OR SAPId__c='')]);
			if(!pMap.isEmpty()){
				System.enqueueJob(new Svc_ProductToSAP(pMap.keySet(), ordIds));
			}else{
				System.enqueueJob(new Svc_OrderToSAP(ordIds));
			}
		}

		// Create Address string from addr. fields
		public static String createAddressTxt(String street, String city, String postalCode, String country){
			String addrTxt = '';
			addrTxt += ((String.isEmpty(street)) ? '' : street) + ', ';
			addrTxt += ((String.isEmpty(city)) ? '' : city) + ', ';
			addrTxt += ((String.isEmpty(postalCode)) ? '' : postalCode) + ', ';
			addrTxt += (String.isEmpty(country)) ? '' : country;
			return addrTxt;
		}

		public static void afterOrderInsert(Id orderId){
			// Create event in google calendar
			System.enqueueJob(new Svc_EventToGC(orderId));
		}

	//===================================================================================================
	// PICKLISTS - PICKLISTS - PICKLISTS - PICKLISTS - PICKLISTS - PICKLISTS - PICKLISTS - PICKLISTS - PI
	//===================================================================================================
		// Returns map of picklist values
		public static Map<string, string> getPickValsMap(String sobj, String field){
			Map<string, string> res = new Map<string, string>();
			Schema.SObjectType targetType = Schema.getGlobalDescribe().get(sobj);
			Sobject Object_name = targetType.newSObject();
			Schema.sObjectType st = Object_name.getSObjectType();
			Schema.DescribeSObjectResult od = st.getDescribe();
			Map<String, Schema.SObjectField> fm = od.fields.getMap();
			Schema.PicklistEntry[] vals = fm.get(field).getDescribe().getPickListValues();
			for (Schema.PicklistEntry a : vals) {
			  res.put(a.getValue(), a.getLabel());
			}
		  return res;
		}
		public static Mdl.PickVal[] getPickVals(String sObjectType, String field ){
			Mdl.PickVal[] res = new Mdl.PickVal[]{};
			Map<string, string> valsMap = getPickValsMap(sObjectType, field);
			for(String i : valsMap.keySet()){res.add(new Mdl.PickVal(i, valsMap.get(i)));}
			return res;
		}
	//===================================================================================================
	// RELATED PICKLISTS - RELATED PICKLISTS - RELATED PICKLISTS - RELATED PICKLISTS - RELATED PICKLISTS 
	//===================================================================================================

	/* Retrieve picklist values as a MAP<String(contains PicklistValue),Mdl.DependentPicklist> */
	public static Map<String, Mdl.DependentPicklist> getDependentPickOptions(Schema.SObjectField ctrlField, Schema.SObjectField theField){
		// validFor property cannot be accessed via a method or a property,
		// so we need to serialize the PicklistEntry object and then deserialize into a wrapper.
		List<Schema.PicklistEntry> contrEntries = ctrlField.getDescribe().getPicklistValues();
		List<Mdl.PicklistEntryWrapper> depEntries = Hlp.wrapPicklistEntries(theField.getDescribe().getPicklistValues());

		// Set up the return container - Map<ControllingValue, List<DependentValues>>
		Map<String, Mdl.DependentPicklist> objResults = new Map<String, Mdl.DependentPicklist>();
		List<String> controllingValues = new List<String>();

		for(Schema.PicklistEntry ple : contrEntries){
			Mdl.DependentPicklist dp = new Mdl.DependentPicklist();
			dp.value = ple.getValue();
			dp.label = ple.getLabel();
			objResults.put(dp.value, dp);
			controllingValues.add(dp.value);
		}

		for(Mdl.PicklistEntryWrapper plew : depEntries){
			String validForBits = base64ToBits(plew.validFor);
			for (Integer i = 0; i < validForBits.length(); i++) {
				// For each bit, in order: if it's a 1, add this label to the dependent list for the corresponding controlling value
				String bit = validForBits.mid(i, 1);
				if (bit == '1') {
					Mdl.DependentPicklist p = new Mdl.DependentPicklist();
					p.value = plew.value;
					p.label = plew.label;
					System.debug('#p' + p);
					objResults.get(controllingValues.get(i)).relatedValues.add(p);
				}
			}
		}

		return objResults;
	}

	// Convert decimal to binary representation (alas, Apex has no native method :-(
	//    eg. 4 => '100', 19 => '10011', etc.
	// Method: Divide by 2 repeatedly until 0. At each step note the remainder (0 or 1).
	// These, in reverse order, are the binary.
	private static String decimalToBinary(Integer val){
		String bits = '';
		while (val > 0) {
			Integer remainder = Math.mod(val, 2);
			val = Integer.valueOf(Math.floor(val / 2));
			bits = String.valueOf(remainder) + bits;
		}
		return bits;
	}

	// Convert a base64 token into a binary/bits representation
	// e.g. 'gAAA' => '100000000000000000000'
	private static String base64ToBits(String validFor){
		if (String.isEmpty(validFor)) return '';

		String validForBits = '';

		for (Integer i = 0; i < validFor.length(); i++){
			String thisChar = validFor.mid(i, 1);
			Integer val = base64Chars.indexOf(thisChar);
			String bits = decimalToBinary(val).leftPad(6, '0');
			validForBits += bits;
		}

		return validForBits;
	}

	private static final String base64Chars = '' +
			'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
			'abcdefghijklmnopqrstuvwxyz' +
			'0123456789+/';

	private static List<Mdl.PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> PLEs) {
		System.debug('#PLEs: '+PLEs);
		return (List<Mdl.PicklistEntryWrapper>)
			JSON.deserialize(JSON.serialize(PLEs), List<Mdl.PicklistEntryWrapper>.class);
	}
		

	/* Retrieve picklist values as a MAP<String,SelectOption[]> */
	private static Map<String,SelectOption[]> m_mapPickValuesOptions = new Map<String,SelectOption[]>();
	public static SelectOption[] getPickValuesOptions(Sobject objName, String fieldName){return getPickValuesOptions(objName, fieldName, null, null);}
	public static SelectOption[] getPickValuesOptions(Sobject objName, String fieldName, String firsLabel, String firstValue){
		String mapKey = objName + '-' + fieldName;
		SelectOption[] options = new SelectOption[]{};
		if(m_mapPickValuesOptions == null  || !m_mapPickValuesOptions.containsKey(mapKey)){
			Schema.sObjectType so = objName.getSObjectType();
			Schema.DescribeSObjectResult dsr = so.getDescribe();
			Map<String, Schema.SObjectField> mapFields = dsr.fields.getMap();
			Schema.PicklistEntry[] picklistValues = mapFields.get(fieldName).getDescribe().getPickListValues();
			for(Schema.PicklistEntry a : picklistValues) {      
				options.add(new SelectOption(a.getValue(), a.getLabel()));
			}
			m_mapPickValuesOptions.put(mapKey, options);
		}else{
			options = m_mapPickValuesOptions.get(mapKey);
		}

		// if first value provided, add it
		if (String.isNotEmpty(firsLabel)) {
			if(firstValue==null){firstValue = '';}
			SelectOption[] optionsWithFirst = new SelectOption[]{};
			optionsWithFirst.add(new SelectOption(firstValue, firsLabel));
			optionsWithFirst.addAll(options);
			return optionsWithFirst;
		}
		return options;
	}

	private static Map<String, Map<String, String>> m_mapPickValues = new Map<String, Map<String, String>>();
	public static Map<String, String> getPickValues(Sobject objName, String fieldName){
		String mapKey = objName + '-' + fieldName;
		Map<String, String> mapValues = new Map<String, String>();
		if(m_mapPickValues == null  || !m_mapPickValues.containsKey(mapKey)){
			Schema.sObjectType so = objName.getSObjectType();
			Schema.DescribeSObjectResult dsr = so.getDescribe();
			Map<String, Schema.SObjectField> mapFields = dsr.fields.getMap();
			Schema.PicklistEntry[] picklistValues = mapFields.get(fieldName).getDescribe().getPickListValues();
			for(Schema.PicklistEntry a : picklistValues) {      
				mapValues.put(a.getValue(),a.getLabel());
			}
			m_mapPickValues.put(mapKey, mapValues);
		}else{
			mapValues = m_mapPickValues.get(mapKey);
		}
		return mapValues;         
	}
	public static String getPickValueLabel(Sobject objName, String fieldName, String value){
		return getPickValues(objName,fieldName).get(value);
	}

	//===================================================================================================
	//  DATED CURRENCY CONVERTOR - DATED CURRENCY CONVERTOR - DATED CURRENCY CONVERTOR - DATED CURRENCY 
	//===================================================================================================

	public static void getDatedCZKValueFromSetQT(Set<Id> syncedQuotes){
		Quote[] syncedQts = [SELECT Id, ProjectSalesFee__c, ProjectSalesFeeValue__c, QuoteTotalDiscount__c, TotalPrice__c, CurrencyIsoCode, Opportunity.CloseDate,
							(SELECT Id, LineCost__c FROM QuoteLineItems)
							FROM Quote WHERE Id IN: syncedQuotes];
		for(Quote syncQt: syncedQts){
			Decimal totalLineCost = 0;
			for(QuoteLineItem qli : syncQt.QuoteLineItems){
				totalLineCost += qli.LineCost__c;
			}
			for(ProjectSalesFee__c psf : [SELECT Id, LowerRange__c, HigherRange__c, Reward__c FROM ProjectSalesFee__c]){
				Decimal quoteTotalDisc = (syncQT.QuoteTotalDiscount__c == null) ? 0 : syncQT.QuoteTotalDiscount__c.setScale(2);
				if(quoteTotalDisc >= psf.LowerRange__c  && quoteTotalDisc <= psf.HigherRange__c){
					Decimal czkTotalPrice = getDatedCZKValue(syncQt.TotalPrice__c, syncQT.CurrencyIsoCode, syncQt.Opportunity.CloseDate);
					syncQT.ProjectSalesFee__c = psf.Reward__c;
					Decimal projectSalesFeeValue = (czkTotalPrice - totalLineCost) * (psf.Reward__c / 100);
					syncQT.ProjectSalesFeeValue__c = (projectSalesFeeValue > 0) ? projectSalesFeeValue : 0;
				}
			}
		}
		update syncedQts;
	}

	public static Map<String,DatedConversionRate[]> m_datedCurrencyListByCodeMap {get;set;}

	//new logic to get Stable Currency values
	public static Decimal getDatedCZKValue(Decimal value, String currencyCode, Date dt) {
		if(value == null || dt == null){
			return 0;
		}
		if (currencyCode == 'CZK') {
			return value;
		}
	
		CurrencyType fromCurrency = [SELECT ConversionRate, DecimalPlaces
									 FROM CurrencyType
									 WHERE IsActive = true
									 AND IsoCode = :currencyCode
									 LIMIT 1];

	
			if (fromCurrency != null) {
				Decimal conversionRate = 1 / fromCurrency.ConversionRate;
				Decimal convertedValue = value * conversionRate;
							
				convertedValue = convertedValue.setScale(2, System.RoundingMode.HALF_UP);
							
				return convertedValue;
			}
		return null;
	}
	
	/**
	* @description compare two values and returns true if they are different
	* @param baseValue The base value for comparison.
	* @param comparedValue The value to compare against the base value
	* @param treatNullAsNoChange if set and comparedValue is null, that won't be treated as different.
	* @return true if values are different, false otherwise. If treatNullAsNoChange is set and comparedValue is null, false will be returned.
	*/
	public static Boolean areValuesDifferent(Object baseValue, Object comparedValue, Boolean treatNullAsNoChange) {

		if (treatNullAsNoChange && (comparedValue == null || String.isEmpty(String.valueOf(comparedValue)))) {
			return false;
		}

		return !(baseValue == comparedValue);
	}
}