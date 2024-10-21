public with sharing class Svc_ContactToSAP {
    private static String SVC_NAME = 'ContactsToSAP';

	public static void syncToSAP(Set<Id> recIds){
		SyncServiceSettings__c stt = SyncServiceSettings__c.getValues(SVC_NAME);
		if(stt.DisableSync__c){ 				SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_ERROR, 503, 'ERROR: Service is disabled'); return; }
		if(recIds == null || recIds.isEmpty()){ SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_WARNING, 200, 'WARNING: recIds is empty'); return; }
		try{
			//SyncUtils.validateAccess(SVC_NAME);
    		sendData(recIds);
		}catch(Exception e){
			SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_ERROR, 0, e.getMessage(), e.getStackTraceString());
		}
	}

	// Prevent calling future method if already running in future context
	public static void sendData(Set<Id> recIds){
		if(System.isFuture()){
			sendContactData(recIds);
		}else{
			sendContactDataFuture(recIds);
		}
	}

	@future (callout=true)
	public static void sendContactDataFuture(Set<Id> recIds){
		sendContactData(recIds);
	}

    public static void sendContactData(Set<Id> recIds){
    	Contact[] cons = [SELECT Id,AccountId FROM Contact WHERE Id IN:recIds];
    	Set<Id> accIds = new Set<Id>();
    	for(Contact c : cons){
    		accIds.add(c.AccountId);
    	}
    	// SBO service for SF Accounts and Contacts has just one endpoint (due to SBO DB structure - one table for both types).
    	// SF Accounts and Contacts are always sent in the same structure from SF (= collection of Accounts + collection of their related Contacts)
    	Account[] recs = [SELECT BillingCity,BillingCountryCode,BillingPostalCode,BillingStateCode,BillingStreet,ShippingCity,ShippingCountryCode,ShippingPostalCode,ShippingStateCode,ShippingStreet,CurrencyIsoCode,Description,Id,IsValidated__c,Name,OwnerSAPId__c,SyncStatus__c,Phone,Website,TaxNo__c,VatNo__c,
							(SELECT AccountId,Department,Description,Email,FirstName,HasOptedOutOfEmail,Id,Name,LastName,AddressTxt__c,MobilePhone,Phone,Salutation,SyncStatus__c,Title FROM Contacts WHERE Id IN:recIds)
							FROM Account WHERE Id IN:accIds];
		String dataStr = JSON.serialize(recs, false);
		HttpResponse res = SyncUtils.sendData(SVC_NAME, dataStr);
		String status;
		if(res.getStatusCode() == 200){
			status = Cst.STATUS_SUCCESS;
			SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_SUCCESS, res.getStatusCode(), 'SUCCESS: contacts synced ('+String.join(new List<Id>(recIds),', ')+')');
		}else{
			status = Cst.STATUS_ERROR;
			SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_ERROR, res.getStatusCode(), 'ERROR - something wents wrong: ' + res.getStatus(), String.valueOf(res), dataStr);
		}
		// Set result recs
		Contact[] consToUpdate = new Contact[]{};
		for(Account acc : recs){
			acc.SyncStatus__c = status;
			for(Contact c : acc.Contacts){
				c.SyncStatus__c = status;
				consToUpdate.add(c);
			}
		}
		update recs;
		update consToUpdate;
	}
}