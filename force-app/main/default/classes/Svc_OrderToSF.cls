@RestResource(urlMapping='/sync/order')
global without sharing class Svc_OrderToSF  {
    private static String SVC_NAME = 'OrderToSF';
    private static SyncServiceSettings__c stt = SyncServiceSettings__c.getValues(SVC_NAME);
    // https://<org-domain>/services/apexrest/sync/order
	
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

        // Insert inbound records - lsit of Orders
        String msg = 'SUSCCESS: Orders synced.';
		String stackTrace;
        String status = Cst.STATUS_SUCCESS;
        res.statusCode = 200;

        try{
			Mdl.SfOrder[] recs = (Mdl.SfOrder[])JSON.deserialize(SyncUtils.getValidJsonForCustomModel(body), Mdl.SfOrder[].class);

			// Get related Account IDs
			Set<String> accIdsSet = new Set<String>();
			Set<String> ordIdsSet = new Set<String>();
			for(Mdl.SfOrder r : recs){
				accIdsSet.add(r.AccountId);
				if(String.isNotEmpty(r.Id)){
					ordIdsSet.add(r.Id); // Only existing recs
				}
			}
            Account[] accs = [SELECT Id,AccountEID__c FROM Account WHERE AccountEID__c IN: accIdsSet];
            Map<String,String> accMap = new Map<String,String>();
            for(Account a : accs){
                accMap.put(a.AccountEID__c,a.Id);
            }

			// Order
			// --------------------------------------------------
			Order__c[] ordsToUpsert = new Order__c[]{};
            for(Mdl.SfOrder r : recs){
                r.AccountId = accMap.get(r.AccountId); // Assign SF IDs
				r.OwnerId = SyncUtils.setSFUserId(r.OwnerSAPId, null);
				r.SyncStatus = Cst.SYNC_STATUS_SUCCESS;
				ordsToUpsert.add(SyncUtils.mapOrderFields(r));
            }
            upsert ordsToUpsert;

			// Order Line Items
			// --------------------------------------------------
			OrderLineItem__c[] olisToInsert = new OrderLineItem__c[]{};
			OrderLineItem__c[] olisToUpdate = new OrderLineItem__c[]{};
			OrderLineItem__c[] olisToDelete = new OrderLineItem__c[]{};

			OrderLineItem__c[] exOlis = [SELECT Id,OrderId__c,LineNum__c FROM OrderLineItem__c WHERE OrderId__c IN:ordIdsSet];
			Map<String,Id> exOlisMap = new Map<String,Id>();
			for(OrderLineItem__c eOli : exOlis){
				exOlisMap.put(eOli.OrderId__c+'-'+eOli.LineNum__c, eOli.Id);
				System.debug(exOlisMap);
			}

			// Order must exists - records have same position in collection
			for(Integer i=0;i<recs.size();i++){
				Order__c eo = ordsToUpsert[i];
				Mdl.SfOrderLineItem[] sfOlis = (recs[i].OrderLineItems.get('records') != null) ? recs[i].OrderLineItems.get('records') : new Mdl.SfOrderLineItem[]{};
				Integer lineNum = 0;
				for(Integer j=0;j<sfOlis.size();j++){
					System.debug(exOlisMap);
					OrderLineItem__c oli = SyncUtils.mapOLIFields(sfOlis[j]);
					Id exOliId = exOlisMap.get(oli.OrderId__c+'-'+lineNum);
					System.debug(exOliId);
					if(j != oli.LineNum__c){
						// Delete missing lines
						if(oli.OrderId__c != null && exOliId != null){
							olisToDelete.add(new OrderLineItem__c(Id=exOliId));
						}
						lineNum++;
					}else{
						if(exOliId == null || oli.OrderId__c == null){
							oli.OrderId__c = eo.Id; // Set Order Id if insert new line
							olisToInsert.add(oli);
						}else{
							oli.Id = exOliId;
							olisToUpdate.add(oli);
						} 
					}
					lineNum++;
				}
			}
			insert olisToInsert;
			update olisToUpdate;
			delete olisToDelete;
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
}