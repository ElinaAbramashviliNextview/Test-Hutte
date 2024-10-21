public class Svc_EventToGC implements Queueable, Database.AllowsCallouts {
	private static String SVC_NAME = 'EventToGC';

	public Id recId{get;set;}

	public Svc_EventToGC(Id rId){
		recId = rId;
	}

	public void execute(QueueableContext qc) {
		String dataInfo;
		try{
			Order__c ord = [SELECT Id, Name, RealizationStartDate__c, RealizationEndDate__c, ShippingAddressTxt__c, OpportunityNo__c, PrimaryContactId__c, 
							PrimaryContactId__r.Name, PrimaryContactId__r.Email, PrimaryContactId__r.Phone, PrimaryContactId__r.MobilePhone,
							OnSiteContactId__c, OnSiteContactId__r.Name, OnSiteContactId__r.Email, OnSiteContactId__r.Phone, OnSiteContactId__r.MobilePhone,
							(SELECT Id, Name, Quantity__c FROM OrderLineItems__r) FROM Order__c WHERE Id =: recId];

			// Prepare product names with count, separated by comma
			String prodsJoin = '';
			String[] prods = new String[]{};
			for(OrderLineItem__c oli : ord.OrderLineItems__r){
				prods.add(oli.Name + ' ('+ Integer.valueOf(oli.Quantity__c) +')');
			}
			prodsJoin = String.join(prods, ',');
			
			//Escape single and double quotes
			String singleEscProdJoin = String.escapeSingleQuotes(prodsJoin);
			String prodJoinWithEscQuotes = singleEscProdJoin.replace('"', '\"');

			//prepare contact info
			String contInfo = '';
			if(ord.OnSiteContactId__c != null){
				Contact c = ord.OnSiteContactId__r;
				contInfo += 'Kontaktní osoba: ';
				if(!String.isBlank(c.Name)){
					contInfo += c.Name;
				}
				if(!String.isBlank(c.MobilePhone) || !String.isBlank(c.Phone)){
					string phn = (!String.isBlank(c.MobilePhone)) ? c.MobilePhone : (!String.isBlank(c.Phone)) ? c.Phone : '';
					contInfo += ', ' + phn;
				}
				if(!String.isBlank(c.Email)){
					contInfo += ', e-mail: ' + c.Email;
				}
			}
			if(!String.isBlank(contInfo)){
				contInfo += ';';
			}
			 // Compose Event Name
			String ordGCName = ord.OpportunityNo__c+' - '+ord.Name;
			 // End Date is probably parsed on GC site as DateTime without timezone
			 // - so, probably, it takes end date as day before (-2 hours) and we have compensate this by adding one day more
			Date endDate = (ord.RealizationStartDate__c != ord.RealizationEndDate__c) ? ord.RealizationEndDate__c.addDays(1) : ord.RealizationEndDate__c;
			GoogleCalendarService.createEvent(ord.RealizationStartDate__c, endDate, ordGCName, contInfo + ' Systém: ' + prodJoinWithEscQuotes, ord.ShippingAddressTxt__c, ord.Id);
			// Summarize info - just for log purposses
			dataInfo =	'Realization Start Date: '+ord.RealizationStartDate__c+'\n'+
						'Realization End Date: '+ord.RealizationEndDate__c+'\n'+
						'Name: '+ord.Name+'\n'+
						'Contact:\n '+contInfo+'\n\n'+
						'System:\n'+prodJoinWithEscQuotes+'\n\n'+
						'Address:\n'+ord.ShippingAddressTxt__c;
		}catch(Exception e){
			SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_ERROR, 0, e.getMessage(), null, e.getStackTraceString());
		}
		SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_SUCCESS, 200, 'SUCCESS: GC created for ('+recId+')', null, dataInfo);
	}
}