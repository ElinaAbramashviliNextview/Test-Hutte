trigger RequestForTechnician on RequestForTechnician__c (before insert, before update, after insert, after update)  { 
/**
SUMMARY:
----------------------------------------------------------------------------------------------------------------------
0. B-U------		> If user fill field Technician - automatic fill Status to 'In Progress'
1. ---AI----        > Change status on Quote to 'To Process' and stage on Opportunity to 'Technical Support'
2. ---A-U---		> Submit to Salesman - Create QLI, QLSI and QLIProduct and link it to Quote
3. BI-------		> Set CurrencyIsoCde by Quote Currency
4. ---A-U---		> Fill Quote Technician by RFT Technician
----------------------------------------------------------------------------------------------------------------------
*/

	// GLOBAL TRIGGER DISABLE
    TriggerSettings__c userTs = TriggerSettings__c.getInstance( UserInfo.getUserID() );
    TriggerSettings__c profileTs = TriggerSettings__c.getInstance( UserInfo.getProfileId() );
    // Return if all or curent trigger disabled
    if((userTs != null && (userTs.Disable_All__c || userTs.DisableRequestForTechnician__c)) || (profileTs != null && (profileTs.Disable_All__c || profileTs.DisableRequestForTechnician__c))) return;

	/* 3. */
	if(Trigger.isBefore && Trigger.isInsert){
		Set<Id> quoteIds = new Set<Id>();
		for(RequestForTechnician__c n : Trigger.new){
			quoteIds.add(n.QuoteId__c);
		}
		Quote[] qts = [SELECT Id, CurrencyIsoCode FROM Quote WHERE Id IN: quoteIds];

		for(RequestForTechnician__c n : Trigger.new){
			for(Quote qt : qts){
				if(n.QuoteId__c == qt.Id){
					n.CurrencyIsoCode = qt.CurrencyIsoCode;				
				}
			}
		}
	}

	/* 0. */
	if(Trigger.isBefore && Trigger.isUpdate){

		for(RequestForTechnician__c n : Trigger.new){
			RequestForTechnician__c oldRFT = Trigger.oldMap.get(n.Id);
			if(oldRFT.TechnicianId__c == null && n.TechnicianId__c != null){
				n.Status__c = Cst.RFT_STATUS_INPROGRESS;
			}
		}
	}

	/* 1. */
	if(Trigger.isAfter){
		if(Trigger.isInsert){
			Set<Id> qtIdsToUpdate = new Set<Id>();
			Set<Id> oppIdsToUpdate = new Set<Id>();
			for(RequestForTechnician__c n : Trigger.new){
				qtIdsToUpdate.add(n.QuoteId__c);
			}
			Quote[] qToUpdate = [SELECT OpportunityId, CurrencyIsoCode, Status FROM Quote WHERE Id IN: qtIdsToUpdate];
			for(Quote qt : qToUpdate){
				qt.Status = Cst.QUOTE_STATUS_TOPROCESS;
				oppIdsToUpdate.add(qt.OpportunityId);
			}
			Opportunity[] oppToUpdate = [SELECT StageName FROM Opportunity WHERE Id IN: oppIdsToUpdate];
			for(Opportunity opp : oppToUpdate){
				opp.StageName = Cst.OPPORTUNITY_STAGE_TECHSUPP;
			}
			update qToUpdate;
			update oppToUpdate;
		}	

		/* 2. */
		if(Trigger.isUpdate){
			Map<Id,Id> rftIdsQuoteIds = new Map<Id,Id>();
			BOM__c[] matsToConvert = new BOM__c[]{};
			ProductDescription__c[] pdsToConvert = new ProductDescription__c[]{};
			QuoteLineItem[] qlisToInsert = new QuoteLineItem[]{};
			QuoteLineSubItem__c[] qlsisToInsert = new QuoteLineSubItem__c[]{};
			QLIDescription__c[] qliDescToInsert = new QLIDescription__c[]{};
			for(RequestForTechnician__c n : Trigger.new){
				RequestForTechnician__c oldRFT = Trigger.oldMap.get(n.Id);
				if(oldRFT.Status__c != Cst.RFT_STATUS_DONE && n.Status__c == Cst.RFT_STATUS_DONE){
					rftIdsQuoteIds.put(n.Id, n.QuoteId__c);
				}
			}
			System.debug('Request For Technician ' + rftIdsQuoteIds);
			Map<Id,Product2> prodsToConvert = new Map<Id,Product2>([SELECT Id, Type__c, UnitCost__c, Description, QuantityUnitOfMeasure, RequestForTechnicianId__c, UnitPriceCZK__c, UnitPriceEUR__c, UnitPriceUSD__c, CurrencyIsoCode, Name, ProductDescriptionCZ__c, ProductDescriptionEN__c FROM Product2 WHERE RequestForTechnicianId__c IN: rftIdsQuoteIds.keySet()]);
			Map<String,Id> pricebookEntryIdMap = new Map<String,Id>();
			PricebookEntry[] priceBooks = [SELECT Id, Product2Id, CurrencyIsoCode FROM PricebookEntry WHERE Product2Id IN: prodsToConvert.keySet()];
			for(PricebookEntry pbe: priceBooks){
				pricebookEntryIdMap.put(pbe.Product2Id+'-'+pbe.CurrencyIsoCode, pbe.Id);
			}

			if(prodsToConvert.size() > 0){
				matsToConvert = [SELECT CurrencyIsoCode, Quantity__c, BundleItemId__c, Type__c, UnitCost__c, QuantityUnitOfMeasure__c, BundleId__c, IsVisibleOnPDF__c, IsVisible__c, IsEditable__c, IsTemplateProduct__c, Position__c,
								BundleItemId__r.Name, BundleItemId__r.Description 
								FROM BOM__c WHERE BundleId__c IN: prodsToConvert.keySet()];

				pdsToConvert = [SELECT TitleCZ__c, TitleEN__c, DescriptionCZ__c, DescriptionEN__c, Name, RowNumber__c, ProductId__c FROM ProductDescription__c WHERE ProductId__c IN: prodsToConvert.keySet()];
			}

			Map<Id,Quote> quoteMap = new Map<Id,Quote>([SELECT Id, CurrencyIsoCode, QuoteDiscount__c FROM Quote WHERE Id IN: rftIdsQuoteIds.values()]);

			// Create Quote Line Items
			System.debug('Products to Convert ' + prodsToConvert);
			if(prodsToConvert.size() > 0){
				for(Product2 prod : prodsToConvert.values()){
					String qCurr = Trigger.newMap.get(prod.RequestForTechnicianId__c).QuoteCurrency__c;
					String qId = Trigger.newMap.get(prod.RequestForTechnicianId__c).QuoteId__c;
					QuoteLineItem qli = new QuoteLineItem();
					qli.QuoteId = rftIdsQuoteIds.get(prod.RequestForTechnicianId__c);
					qli.Product2Id = prod.Id;
					qli.ProductName__c = prod.Name;
					qli.Description = prod.Description;
					qli.LineCost__c = prod.UnitCost__c;
					qli.Quantity = 1;
					qli.Discount = 0;
					qli.RowTotalDiscount__c = 0;
					qli.RowDiscount__c = 0;
					Decimal unitPrice = (Decimal)prod.get('UnitPrice'+qCurr+'__c');
					qli.UnitPrice = unitPrice;
					qli.UnitPrice__c = unitPrice;
					qli.PricebookEntryId = pricebookEntryIdMap.get(prod.Id+'-'+qCurr);
					if(quoteMap.get(qId).QuoteDiscount__c == null){
						qli.RowTotalPrice__c = unitPrice;
					}else{
						qli.RowTotalPrice__c = unitPrice * (1 - (quoteMap.get(qId).QuoteDiscount__c / 100));
					}
					qli.ProductDescriptionCZ__c = prod.ProductDescriptionCZ__c;
					qli.ProductDescriptionEN__c = prod.ProductDescriptionEN__c;
					
					qlisToInsert.add(qli);	
				}
				insert qlisToInsert;
			}

			// Create Quote Line Sub Items
			System.debug('Materials to Convert ' + matsToConvert);
			if(qlisToInsert.size() > 0){
				for(QuoteLineItem qli: qlisToInsert){
					if(matsToConvert.size() > 0){
						for(BOM__c bom: matsToConvert){
							if(qli.Product2Id == bom.BundleId__c){
							QuoteLineSubItem__c qlsi = new QuoteLineSubItem__c();
								qlsi.QuoteLineItemId__c = qli.Id;
								qlsi.Name = bom.BundleItemId__r.Name;
								qlsi.Product2Id__c = bom.BundleItemId__c;
								qlsi.ProductName__c = bom.BundleItemId__r.Name;
								qlsi.Description__c = bom.BundleItemId__r.Description;
								qlsi.CurrencyIsoCode = bom.CurrencyIsoCode;
								qlsi.Quantity__c = bom.Quantity__c;
								qlsi.IsVisible__c = bom.IsVisible__c;
								qlsi.IsEditable__c = bom.IsEditable__c;
								qlsi.IsTemplateProduct__c = bom.IsTemplateProduct__c;
								qlsi.IsVisibleOnPDF__c = bom.IsVisibleOnPDF__c;
								qlsi.Position__c = bom.Position__c;
								qlsisToInsert.add(qlsi);
							}
						}
					}
					if(pdsToConvert.size() > 0){
						for(ProductDescription__c pd : pdsToConvert){
							if(qli.Product2Id == pd.ProductId__c){
								QLIDescription__c qliDesc = new QLIDescription__c();
								qliDesc.QuoteLineItemId__c = qli.Id;
								qliDesc.TitleCZ__c = pd.TitleCZ__c;
								qliDesc.TitleEN__c = pd.TitleEN__c;
								qliDesc.DescriptionCZ__c = pd.DescriptionCZ__c;
								qliDesc.DescriptionEN__c = pd.DescriptionEN__c;
								qliDesc.RowNumber__c = pd.RowNumber__c;
								qliDesc.Name = pd.Name;
								qliDescToInsert.add(qliDesc);
							}
						}
					}
				}
				insert qlsisToInsert;
				insert qliDescToInsert;
			}

			
			/* 4. */
			Map<Id,Id> technicianIdByQuoteIds = new Map<Id,Id>();
			for(RequestForTechnician__c n : Trigger.new){
				RequestForTechnician__c oldRFT = Trigger.oldMap.get(n.Id);
				if(oldRFT.TechnicianId__c != n.TechnicianId__c){
					technicianIdByQuoteIds.put(n.QuoteId__c, n.TechnicianId__c);
				}
			}
			Quote[] quoteTechnician = [SELECT Id, TechnicianUserId__c FROM Quote WHERE Id IN: technicianIdByQuoteIds.keySet()];
			for(Quote qt : quoteTechnician){
				qt.TechnicianUserId__c = technicianIdByQuoteIds.get(qt.Id);
			}

			Quote[] qtsToUpdate = quoteMap.values();
			for(Quote q : qtsToUpdate){
				q.Status = Cst.QUOTE_STATUS_PROCESSED;
			}
			
			qtsToUpdate.addAll(quoteTechnician);
			update qtsToUpdate;
		}
	}
}