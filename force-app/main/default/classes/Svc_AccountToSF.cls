@RestResource(urlMapping='/sync/account')
global without sharing class Svc_AccountToSF {
    private static String SVC_NAME = 'AccountToSF';
    private static SyncServiceSettings__c stt = SyncServiceSettings__c.getValues(SVC_NAME);
    // https://<org-domain>/services/apexrest/sync/account


    @HttpPost
    global static void doPost() {
        if(stt.DisableSync__c){ SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_ERROR, 503, 'ERROR: Service is disabled'); return; }

	    // Get valid settings
	    String validToken = 'Baerer '+stt.Token__c;
	    // Also for testing
	    if(Test.isRunningTest()){ validToken = 'Baerer '+'XXXXX'; }

	    RestRequest req = RestContext.request;
	    RestResponse res = RestContext.response;

	    String token = req.headers.get('token');
        String body = (req.requestBody != null) ? req.requestBody.toString() : '';
        System.debug('body: '+body);

        // Validate token
        if(String.isEmpty(token) || token != validToken){
            res.statusCode = 401;
            res.responseBody = Blob.valueOf('Invalid token - requested ('+token+')');
            return;
        }

        // Insert inbound records - lsit of Accounts
        String msg = 'SUSCCESS: Accounts synced.';
		String stackTrace;
        String status = Cst.STATUS_SUCCESS;
        res.statusCode = 200;
        try{
            Account[] recs = (Account[])JSON.deserialize(body, Account[].class);
			// Get existing Accounts
			Set<Id> exRecIds = new Set<Id>();
			for(Account a : recs){
				if(a.Id != null){ exRecIds.add(a.Id); }
			}			
			Account[] exRecs = [SELECT Id, CurrencyIsoCode, OwnerId, OwnerSAPId__c FROM Account WHERE Id IN:exRecIds];
			Map<Id,Account> exRecMap = new Map<Id,Account>(exRecs);
			Account[] accsInApproval = new Account[]{};
            for(Account r : exRecs){
				// check locked status, if so add to accsInApproval to unlock before update
				if(Approval.isLocked(r)){
					accsInApproval.add(r);
				}
			}

            for(Account r : recs){
                // Set owner
				Account exAcc = exRecMap.get(r.Id);
				String exOwnrSAPId = (exAcc != null) ? exAcc.OwnerSAPId__c : null;
                r.OwnerId = SyncUtils.setSFUserId(r.OwnerSAPId__c, exOwnrSAPId);

				// If state is not valid in SF, add text to City field
				if(r.BillingStateCode != null && !checkHasValidStateCode(r.BillingCountryCode, r.BillingStateCode)){
					if(String.isNotEmpty(r.BillingState)){ r.BillingStreet += ' ('+r.BillingState+')'; }
					r.BillingStateCode = null;
				}
				if(r.ShippingStateCode != null && !checkHasValidStateCode(r.ShippingCountryCode, r.ShippingStateCode)){
					if(String.isNotEmpty(r.ShippingState)){ r.ShippingStreet += ' ('+r.ShippingState+')'; }
					r.ShippingStateCode = null;
				}

				// Set default Currency (EUR) if not present from SAP or already set in SF
				if(r.CurrencyIsoCode != 'CZK' && r.CurrencyIsoCode != 'EUR' && r.CurrencyIsoCode != 'USD'){
					Account exRec = exRecMap.get(r.Id);
					r.CurrencyIsoCode = (exRec != null) ? exRec.CurrencyIsoCode : 'EUR';
				}
			}
			// if some records are locked, unlock them first
			if(!accsInApproval.isEmpty()){
				Approval.unlock(accsInApproval);
			}
			// do actual accounts update
			upsert recs;
			//if some records were locked, lock them back
			if(!accsInApproval.isEmpty()){
				Approval.lock(accsInApproval);
			}
            // Owner should be always filled in - must be default
        }catch(Exception e){
            status = Cst.STATUS_ERROR;
            res.statusCode = 400;
            msg = e.getMessage();
			stackTrace = e.getStackTraceString();
			res.responseBody = Blob.valueOf(msg+'\n'+stackTrace);
        }
		
		// Force set Response Status by settings
		if(stt.ForceStatusCode__c != null){ res.statusCode = (Integer)stt.ForceStatusCode__c; msg = 'FORCED STATUS CODE:\n'+msg; }

        SyncUtils.logServiceActivity(SVC_NAME, status, res.statusCode, msg, stackTrace, Hlp.getStringWithLength(body,32000));
        return;
	}

	private static Boolean checkHasValidStateCode(String countryCode, String stateCode){
		Map<String,Mdl.DependentPicklist> mapPlOpts = Hlp.getDependentPickOptions(Account.BillingCountryCode,Account.BillingStateCode); // Values are the same as for Shipping address
		Mdl.DependentPicklist bc = mapPlOpts.get(countryCode);
		Boolean hasExOpt = false;
		if(bc != null && !bc.relatedValues.isEmpty()){
			for(Mdl.DependentPicklist rv : bc.relatedValues){
				if(rv.value == stateCode){
					hasExOpt = true;
					break;
				}
			}
		}
		return hasExOpt;
	}
}