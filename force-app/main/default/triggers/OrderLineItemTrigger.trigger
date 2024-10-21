trigger OrderLineItemTrigger on OrderLineItem__c (before insert, before update, after insert) {
	public static String PROD_TYPE_M_LATKA = 'M-LATKA';
	public static String PROD_SPEC_EL_SOCKET_TYPE = '8';
	public static String PROD_SPEC_POWER_CABLE = '7';
	public static String PROD_TYPE_S_SLUZBY = 'S-SLUZBY'; 

	if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
		Map<Id,Id> oppIdByOliId = new Map<Id,Id>();
		Set<Id> orderIds = new Set<Id>();
		Set<Id> oppIDs = new Set<Id>();
		Set<Id> qliIds = new Set<Id>();
		
		for(OrderLineItem__c n :  trigger.new){
			if(n.OrderId__c != null){
				orderIds.add(n.OrderId__c);
			}
			if(n.QuoteLineItemId__c != null){
				qliIds.add(n.QuoteLineItemId__c);
			}
		}

		Map<Id,Order__c> orsMap = new Map<Id,Order__c>([SELECT Id, Name,
			OpportunityId__r.OpportunityNo__c, OpportunityId__r.Name, OpportunityId__r.CloseDate, OpportunityId__r.Owner.Name, OpportunityId__r.RealizationStartDate__c,
			OpportunityId__r.RealizationEndDate__c, OpportunityId__r.ProjectManagerId__r.Name, OpportunityId__r.ResponsibleTechnicianId__r.Name, OpportunityId__r.Country__c
			FROM Order__c 
			WHERE Id IN: orderIds]);

		// Product2Id__r.Specification__c  not 10 or 11 - same as in Quote Manager
		Map<Id,QuoteLineItem> qliMap = new Map<Id,QuoteLineItem>([SELECT Id, ProductName__c, Product2.Family, Product2.BusinessName__c, Product2.Specification__c, Product2.Type__c, Description, TC_ShippingCost__c, TC_MaterialShippingCost__c,
			TC_AssemblyCost__c, TC_AccommodationCost__c, RelatedOptionalEquipment__c, IsTransport__c,
				(SELECT Id,ProductName__c, Product2Id__r.Family, Product2Id__r.BusinessName__c, Product2Id__r.Specification__c, Product2Id__r.Type__c
				FROM QuoteLineSubItems__r 
				WHERE IsVisible__c = true AND Product2Id__r.Specification__c != '10' AND Product2Id__r.Specification__c != '11')
			FROM QuoteLineItem 
			WHERE Id IN: qliIds]);

		Map<Id, QuoteLineItem[]> qlisByQuoteLineItemId = new Map<Id, QuoteLineItem[]>();
		QuoteLineItem transportQuoteLine = new QuoteLineItem();
		for(QuoteLineItem qli: qliMap.values()){
			System.debug('### qlimap: ' + qli.ProductName__c);
			System.debug('### qlimap: ' + qli.RelatedOptionalEquipment__c);
			if(qli.IsTransport__c){
				transportQuoteLine = qli;
			}
			if(qli.RelatedOptionalEquipment__c == null){
				continue;
			}
			QuoteLineItem[] tmp = qlisByQuoteLineItemId.get(qli.RelatedOptionalEquipment__c);
			if(tmp == null){
				tmp = new QuoteLineItem[]{};
				qlisByQuoteLineItemId.put(qli.RelatedOptionalEquipment__c, tmp);
			}
			tmp.add(qli);
		}

		System.debug('map: ' + qlisByQuoteLineItemId);

		

		for(OrderLineItem__c n :  trigger.new){
			Order__c ord = orsMap.get(n.OrderId__c);
			QuoteLineItem qli = qliMap.get(n.QuoteLineItemId__c);

			String ps1 = null;
			String ps2 = null;
			String ps3 = null;
			String ps4 = '';

			for(QuoteLineSubItem__c qlsi : qli.QuoteLineSubItems__r){
				System.debug('### qlsi name: ' + qlsi.ProductName__c);
				System.debug('### qlsi spec: ' + qlsi.Product2Id__r.Specification__c);
				System.debug('### qlsi type: ' + qlsi.Product2Id__r.Type__c);
				// el. socket type
				if(!String.isBlank(qlsi.Product2Id__r.Specification__c) && qlsi.Product2Id__r.Specification__c.split(';').contains(PROD_SPEC_EL_SOCKET_TYPE) && ps1 == null){
					ps1 = qlsi.Product2Id__r.BusinessName__c;
				}

				// power cable
				if(!String.isBlank(qlsi.Product2Id__r.Specification__c) && qlsi.Product2Id__r.Specification__c.split(';').contains(PROD_SPEC_POWER_CABLE) && ps2 == null){
					ps2 = qlsi.Product2Id__r.BusinessName__c;
				}

				// M-Latka
				if(qlsi.Product2Id__r.Type__c == PROD_TYPE_M_LATKA && ps3 == null){
					ps3 = qlsi.Product2Id__r.BusinessName__c;
				}

				// s_vyrobek
				if(qlsi.Product2Id__r.Type__c == PROD_TYPE_S_SLUZBY){
					ps4 += qlsi.Product2Id__r.BusinessName__c+';';
				}
			}

			// try to get additional s-sluzby line items added under qutelineitem
			QuoteLineItem[] qlis = qlisByQuoteLineItemId.get(qli.Id);
			if(qlis != null){
				for(QuoteLineItem tmp : qlis){
					System.debug('### qli name: ' + tmp.ProductName__c);
					System.debug('### qli type: ' + tmp.Product2.Type__c);
					if(tmp.Product2.Type__c == PROD_TYPE_S_SLUZBY){
						ps4 += tmp.Product2.BusinessName__c+';';
					}
				}
			}

			n.OpportunityNo__c = ord.OpportunityId__r.OpportunityNo__c;
			n.OppCloseDate__c = ord.OpportunityId__r.CloseDate;
			n.OppCountry__c = ord.OpportunityId__r.Country__c;
			n.OppName__c = ord.OpportunityId__r.Name;
			n.OppOwnerName__c = ord.OpportunityId__r.Owner.Name;
			n.OppProjectManager__c = ord.OpportunityId__r.ProjectManagerId__r.Name;
			n.OppRealizationEndDate__c = ord.OpportunityId__r.RealizationEndDate__c;
			n.OppRealizationStartDate__c = ord.OpportunityId__r.RealizationStartDate__c;
			n.OppResponsibleTechnician__c = ord.OpportunityId__r.ResponsibleTechnicianId__r.Name;
			n.ProductFamily__c = qli.Product2.Family;

			n.QliBussinesName__c = qli.Product2.BusinessName__c;
			n.QliDescription__c = qli.Description;
			n.QliTCAccommodationCost__c = transportQuoteLine.TC_AccommodationCost__c;
			n.QliTCAssemblyCost__c = transportQuoteLine.TC_AssemblyCost__c;
			n.QliTCMaterialShippingCost__c = transportQuoteLine.TC_MaterialShippingCost__c;
			n.QliTCShippingCost__c = transportQuoteLine.TC_ShippingCost__c;
			n.QliTcShipping__c = (transportQuoteLine.TC_ShippingCost__c == null || transportQuoteLine.TC_ShippingCost__c == 0) ? 'Ne' : 'Ano';
			n.QliTcMaterialShipping__c = (transportQuoteLine.TC_MaterialShippingCost__c == null || transportQuoteLine.TC_MaterialShippingCost__c == 0) ? 'Ne' : 'Ano';
			n.QLI_PS1__c = ps1;
			n.QLI_PS2__c = ps2;
			n.QLI_PS3__c = ps3;
			n.QLI_PS4__c = ps4;
			n.IsAddition__c = (qli.RelatedOptionalEquipment__c != null || qli.Id == transportQuoteLine.Id);
		}
	}

	if(trigger.isAfter || trigger.isUpdate){
		
		
		for(OrderLineItem__c n :  trigger.new){
			// skip additions
			if(n.IsAddition__c){
				continue;
			}

			OrderLineZapItem__c[] olzis = new OrderLineZapItem__c[]{};
			//create temporary zap items
			for (Integer i = 0; i < n.Quantity__c; i++) {
				OrderLineZapItem__c olzi = new OrderLineZapItem__c(OrderLineItem__c = n.Id);
				olzi.OpportunityNo__c = n.OpportunityNo__c;
				olzi.OppCloseDate__c = DateTime.newInstance(n.OppCloseDate__c, Time.newInstance(0, 0, 0, 0)).format('MM/dd/YY');
				olzi.OppCountry__c = n.OppCountry__c;
				olzi.OppName__c = n.OppName__c;
				olzi.OppOwnerName__c = n.OppOwnerName__c;
				olzi.OppProjectManager__c = n.OppProjectManager__c;
				olzi.OppRealizationEndDate__c = DateTime.newInstance(n.OppRealizationEndDate__c, Time.newInstance(0, 0, 0, 0)).format('MM/dd/YY');
				olzi.OppRealizationStartDate__c = DateTime.newInstance(n.OppRealizationStartDate__c, Time.newInstance(0, 0, 0, 0)).format('MM/dd/YY');
				olzi.OppResponsibleTechnician__c = n.OppResponsibleTechnician__c;
				olzi.ProductFamily__c = n.ProductFamily__c;
				olzi.QliBussinesName__c = n.QliBussinesName__c;
				olzi.QliDescription__c = n.QliDescription__c;
				olzi.QliTCAccommodationCost__c = String.valueOf(n.QliTCAccommodationCost__c);
				olzi.QliTCAssemblyCost__c = String.valueOf(n.QliTCAssemblyCost__c);
				olzi.QliTCMaterialShippingCost__c = String.valueOf(n.QliTCMaterialShippingCost__c);
				olzi.QliTCShippingCost__c = String.valueOf(n.QliTCShippingCost__c);
				olzi.QliTcShipping__c = n.QliTcShipping__c;
				olzi.QliTcMaterialShipping__c = n.QliTcMaterialShipping__c;
				olzi.QLI_PS1__c = n.QLI_PS1__c;
				olzi.QLI_PS2__c = n.QLI_PS2__c;
				olzi.QLI_PS3__c = n.QLI_PS3__c;
				olzi.QLI_PS4__c = n.QLI_PS4__c;

				olzis.add(olzi);
			}

			if(!olzis.isEmpty()){
				insert olzis;

				// clean record older than 2 months
				OrderLineZapItem__c[] tmp = [SELECT Id FROM OrderLineZapItem__c WHERE CreatedDate <: System.now().addMonths(-2)];
				delete tmp;
			}
		}
	}
}