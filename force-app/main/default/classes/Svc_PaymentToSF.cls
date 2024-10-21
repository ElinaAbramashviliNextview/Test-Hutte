@RestResource(urlMapping='/sync/payment')
global without sharing class Svc_PaymentToSF  {
    private static String SVC_NAME = 'PaymentToSF';
    private static SyncServiceSettings__c stt = SyncServiceSettings__c.getValues(SVC_NAME);
    // https://<org-domain>/services/apexrest/sync/payment

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

        // Insert inbound records - lsit of Payment
        String msg = 'SUSCCESS: Payments synced.';
		String stackTrace;
		String errStr = '';
        String status = Cst.STATUS_SUCCESS;
        res.statusCode = 200;
        try{
            Payment__c[] recs = (Payment__c[])JSON.deserialize(body, Payment__c[].class);
            // Get related records IDs
            Set<String> accIdsSet = new Set<String>();
			Set<String> ordIdsSet = new Set<String>();
            Set<String> invIdsSet = new Set<String>();
            for(Payment__c r : recs){
                // OpportunityId__c - Opp SF ID
                accIdsSet.add(r.AccountSAPId__c); // Account SAP Id
				ordIdsSet.add(r.SAPOrderId__c); // Order SAP ID 
                invIdsSet.add(r.InvoiceSAPId__c); // Invoice SAP ID
            }
            Account[] accs = [SELECT Id,AccountEID__c FROM Account WHERE AccountEID__c IN: accIdsSet];
            Map<String,String> accMap = new Map<String,String>();
            for(Account a : accs){
                accMap.put(a.AccountEID__c,a.Id);
            }
            Invoice__c[] invs = [SELECT Id,SAPId__c FROM Invoice__c WHERE SAPId__c IN: invIdsSet];
            Map<String,String> invMap = new Map<String,String>();
            for(Invoice__c i : invs){
                invMap.put(i.SAPId__c,i.Id);
            }
            Order__c[] ords = [SELECT Id,EId__c FROM Order__c WHERE EId__c IN: ordIdsSet];
            Map<String,String> ordMap = new Map<String,String>();
            for(Order__c o : ords){
                ordMap.put(o.EId__c,o.Id);
            }

            // Assign SF IDs
            for(Payment__c r : recs){
				// It's always necessary to validate if null is really null and not 'null' string :)
				// - and also preffer assignment by SAP ID than SF ID 
				try{
					String tmpAId = r.AccountId__c;
					String accId = accMap.get(r.AccountSAPId__c);
					r.AccountId__c = (tmpAId != null && tmpAId != 'null' && tmpAId != accId) ? tmpAId : accId;
				}catch(Exception e){
					status = Cst.STATUS_WARNING;
					msg += 'Unable to pair Account for '+r.SAPId__c+': r.AccountId__c = '+r.AccountId__c+'; r.AccountSAPId__c = '+r.AccountSAPId__c;
					r.SyncIssueDescription__c += 'WARN: '+e.getMessage() + '; ST: '+e.getStackTraceString();
				}
				try{
					String tmpIId = r.InvoiceId__c;
					String invId = invMap.get(r.InvoiceSAPId__c);
					r.InvoiceId__c = (tmpIId != null && tmpIId != 'null' && tmpIId != invId) ? tmpIId : invId;
				}catch(Exception e){
					status = Cst.STATUS_WARNING;
					msg += 'Unable to pair Order for '+r.SAPId__c+': r.InvoiceId__c = '+r.InvoiceId__c+'; r.InvoiceSAPId__c = '+r.InvoiceSAPId__c;
					r.SyncIssueDescription__c += 'WARN: '+e.getMessage() + '; ST: '+e.getStackTraceString();
				}
				try{
					String tmpOId = r.OrderId__c;
					String ordId = ordMap.get(r.SAPOrderId__c);
					r.OrderId__c = (tmpOId != null && tmpOId != 'null' && tmpOId != ordId) ? tmpOId : ordId;
				}catch(Exception e){
					status = Cst.STATUS_WARNING;
					msg += 'Unable to pair Order for '+r.SAPId__c+': r.OrderId__c = '+r.OrderId__c+'; r.SAPOrderId__c = '+r.SAPOrderId__c;
					r.SyncIssueDescription__c += 'WARN: '+e.getMessage() + '; ST: '+e.getStackTraceString();
				}
            }
            Database.SaveResult[] srs = Database.insert(recs, false);
			for(Integer i=0; i<srs.size();i++){
				if(!srs[i].isSuccess()){
					errStr += 'ERROR: '+srs[i].getErrors()+'\n\n'+'RECORD: '+JSON.serializePretty(recs[i]+'\n\n');
				}
			}
        }catch(Exception e){
            status = Cst.STATUS_ERROR;
            res.statusCode = 400;
            msg = e.getMessage();
			stackTrace = e.getStackTraceString();
			res.responseBody = Blob.valueOf(msg+'\n'+stackTrace);
        }

		// Force set Response Status by settings
		if(stt.ForceStatusCode__c != null){ res.statusCode = (Integer)stt.ForceStatusCode__c; msg = 'FORCED STATUS CODE:\n'+msg; }
		if(String.isNotEmpty(errStr)){
			stackTrace = errStr;
			status = Cst.STATUS_WARNING;
			msg = 'WARNING: Some records failed to insert!';
		}
        SyncUtils.logServiceActivity(SVC_NAME, status, res.statusCode, msg, stackTrace, Hlp.getStringWithLength(body,32000));
        return;
    }
}