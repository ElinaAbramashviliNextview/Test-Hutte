@RestResource(urlMapping='/sync/invoice')
global without sharing class Svc_InvoiceToSF{
    private static String SVC_NAME = 'InvoiceToSF';
    private static SyncServiceSettings__c stt = SyncServiceSettings__c.getValues(SVC_NAME);
    // https://<org-domain>/services/apexrest/sync/invoice
        
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
        String msg = 'SUSCCESS: Invoices synced.';
        String stackTrace = '';
        String errStr = '';
        String status = Cst.STATUS_SUCCESS;
        res.statusCode = 200;
        try{
			Invoice__c[] invcsToUpsert = new Invoice__c[]{};
            Invoice__c[] recs = (Invoice__c[])JSON.deserialize(body, Invoice__c[].class);
            Set<String> accIdsSet = new Set<String>();
            Set<String> invIdsSet = new Set<String>();
            for(Invoice__c r : recs){
                accIdsSet.add(r.AccountId__c);
                if(String.isNotEmpty(r.CanceledInvoiceSAPId__c)){
                    invIdsSet.add(r.CanceledInvoiceSAPId__c);
                }
            }
            
			// Get related data
			Account[] accs = [SELECT Id,AccountEID__c FROM Account WHERE AccountEID__c IN: accIdsSet];
            Map<String,String> accMap = new Map<String,String>();
            for(Account a : accs){
                accMap.put(a.AccountEID__c,a.Id);
            }
            Invoice__c[] exInvcs = [SELECT Id,SAPId__c FROM Invoice__c WHERE SAPId__c IN: invIdsSet];
            Map<String,String> invMap = new Map<String,String>();
            for(Invoice__c inv : exInvcs){
                invMap.put(inv.SAPId__c,inv.Id);
            }

			// Invoice data
            for(Invoice__c r : recs){
                r.AccountId__c = accMap.get(r.AccountId__c); // Assign SF IDs
                if(String.isNotEmpty(r.CanceledInvoiceSAPId__c)){
                    r.CanceledInvoiceId__c = invMap.get(r.CanceledInvoiceSAPId__c);
                }
			}
            Database.UpsertResult[] srs = Database.upsert(recs, Invoice__c.SAPId__c.getDescribe().getSObjectField(), false);
			for(Integer i=0; i<srs.size();i++){
				if(!srs[i].isSuccess()){
                    errStr += 'ERROR: '+srs[i].getErrors()+'\n\n'+'RECORD: '+JSON.serializePretty(recs[i]+'\n\n');
				}
			}
            if(String.isNotEmpty(errStr)){
                stackTrace += '\n'+errStr;
                status = Cst.STATUS_WARNING;
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

        SyncUtils.logServiceActivity(SVC_NAME, status, res.statusCode, msg, stackTrace, Hlp.getStringWithLength(body,32000));
        return;
    }
}