public with sharing class Svc_AccountToSAP {
    private static String SVC_NAME = 'AccountToSAP';

    public static void syncToSAP(Set<Id> recIds){
        SyncServiceSettings__c stt = SyncServiceSettings__c.getValues(SVC_NAME);
        if(stt.DisableSync__c){ SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_ERROR, 503, 'ERROR: Service is disabled'); return; }
        try{
            //SyncUtils.validateAccess(SVC_NAME);
            sendData(recIds);
        }catch(Exception e){
            SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_ERROR, 0, e.getMessage(), e.getStackTraceString());
        }
    }

    @future (callout=true)
    public static void sendData(Set<Id> recIds){
        // SBO service for SF Accounts and Contacts has just one endpoint (due to SBO DB structure - one table for both types).
        // SF Accounts and Contacts are always sent in the same structure from SF (= collection of Accounts + collection of their related Contacts)
        Account[] recs = [SELECT BillingCity,BillingCountryCode,BillingPostalCode,BillingStateCode,BillingStreet,ShippingCity,ShippingCountryCode,ShippingPostalCode,ShippingStateCode,ShippingStreet,CurrencyIsoCode,Description,Id,IsValidated__c,Name,OwnerSAPId__c,Phone,SyncStatus__c,Website,TaxNo__c,VatNo__c,
                            (SELECT AccountId,Department,Description,Email,FirstName,HasOptedOutOfEmail,Id,Name,LastName,AddressTxt__c,MobilePhone,Phone,Salutation,SyncStatus__c,Title FROM Contacts)
                            FROM Account WHERE Id IN:recIds];
        String dataStr = JSON.serialize(recs, false);
        HttpResponse res = SyncUtils.sendData(SVC_NAME, dataStr);
        String status;
        if(res.getStatusCode() == 200){
            status = Cst.STATUS_SUCCESS;
            SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_SUCCESS, res.getStatusCode(), 'SUCCESS: accounts synced ('+String.join(new List<Id>(recIds),', ')+')');
        }else{
            status = Cst.STATUS_ERROR;
            SyncUtils.logServiceActivity(SVC_NAME, Cst.STATUS_ERROR, res.getStatusCode(), 'ERROR - something wents wrong: ' + res.getStatus(), res.getBody(), recIds.toString(), dataStr);
        }
        // Set result recs
        Contact[] consToUpdate = new Contact[]{};
        Account[] accsInApproval = new Account[]{};

        for(Account acc : recs){
            // check locked status, if so add to accsInApproval to unlock before update
            if(Approval.isLocked(acc.Id)){
                accsInApproval.add(acc);
            }
            acc.SyncStatus__c = status;
            for(Contact c : acc.Contacts){
                c.SyncStatus__c = status;
                consToUpdate.add(c);
            }
        }
        if(!accsInApproval.isEmpty()){
            Approval.unlock(accsInApproval);
        }
        // do actual accounts update
        upsert recs;
        //if some records were locked, lock them back
        if(!accsInApproval.isEmpty()){
            Approval.lock(accsInApproval);
        }
        update consToUpdate;
    }
}