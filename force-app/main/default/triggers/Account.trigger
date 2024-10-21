trigger Account on Account (before insert, before update, after insert, after update) {
/**
SUMMARY:
----------------------------------------------------------------------------------------------------------------------
0. B-U------        > Sync Account to SAP if FORCE Sync
                        (Account records are synced when Opp created in standard way, so it's triggered from Opportunity trigger)
1. BIU------        > Preset values
                        - If Shipping City (required for Sync To SAP) is empty - fill in shipping address fields from Billing Address
                        - If User's SAP ID is not set or was changed - get it from user record
2. ----AIU--        > Start Approval Process

    NOTE:
        - This trigger should be disabled in the custom settings for Home-Site User (external requests)
----------------------------------------------------------------------------------------------------------------------
*/

    // GLOBAL TRIGGER DISABLE
    TriggerSettings__c userTs = TriggerSettings__c.getInstance( UserInfo.getUserID() );
    TriggerSettings__c profileTs = TriggerSettings__c.getInstance( UserInfo.getProfileId() );
    // Return if all or curent trigger disabled
    if((userTs != null && (userTs.Disable_All__c || userTs.Disable_Acc_AccToSAP__c)) || (profileTs != null && (profileTs.Disable_All__c || profileTs.Disable_Acc_AccToSAP__c))) return;

    // Also invoking by future method (update by Sync Service) should be disabled
    if(System.isFuture()){ return; }

    if(Trigger.isBefore && Trigger.isUpdate){
        /* 0. */
        Set<Id> accIds = new Set<Id>();
        for(Account n : Trigger.new){
            if(n.SyncStatus__c == Cst.SYNC_STATUS_FORCE){
                accIds.add(n.Id);
                n.SyncStatus__c = Cst.SYNC_STATUS_SYNCING;
            }
            if(n.DiscountAccount__c != null && n.DiscountAccount__c != Trigger.oldMap.get(n.Id).DiscountAccount__c){
                n.OldAccountDiscount__c = Trigger.oldMap.get(n.Id).DiscountAccount__c;
            }
        }
        if(!accIds.isEmpty()){
            Svc_AccountToSAP.syncToSAP(accIds);
        }
    }

    /* 1. */    
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
        Map<Id,User> usrsMap = new Map<Id,User>([SELECT Id,SAPId__c FROM User WHERE IsActive = true]);

        for(Account n : Trigger.new){
            // If User's SAP ID is not set or was changed - get it from user record
            Account o = (Trigger.isUpdate) ? Trigger.oldMap.get(n.Id) : null;
            if(String.isEmpty(n.OwnerSAPId__c) || (Trigger.isUpdate && o.OwnerId != n.OwnerId)){
                n.OwnerSAPId__c = usrsMap.get(n.OwnerId)?.SAPId__c;
            }

            // We suppose that if Shipping city is not set,
            // also other parts of shipping addres are empty
            if(String.isEmpty(n.ShippingCity)){
                n.ShippingCountryCode = n.BillingCountryCode;
                n.ShippingPostalCode = n.BillingPostalCode;
                n.ShippingStateCode = n.BillingStateCode;
                n.ShippingCity = n.BillingCity;
                n.ShippingStreet = n.BillingStreet;
            }
        }
    }
    /* 2. */
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            ApprovalSettings__c profileAS = ApprovalSettings__c.getInstance(UserInfo.getProfileId());
            if(profileAS.NeedApprove__c){
                for(Account n : Trigger.new){
                    if(n.DiscountAccount__c > 15){
                        if(!Approval.isLocked(n.Id)){
                            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                            req1.setSkipEntryCriteria(true);
                            req1.setObjectId(n.Id);
                            req1.setSubmitterId(UserInfo.getUserId());
                            req1.setProcessDefinitionNameOrId('ApproveAccountDiscount');
                            Approval.ProcessResult result = Approval.process(req1);
                            System.debug('Approval Process Result ' + result);
                        }
                    }
                }
            }
        }
        if(Trigger.isUpdate){
            ApprovalSettings__c profileAS = ApprovalSettings__c.getInstance(UserInfo.getProfileId());
            if(profileAS.NeedApprove__c){
                for(Account n : Trigger.new){
                    Account o = Trigger.oldMap.get(n.Id);
                    if(n.Name != o.Name || (n.DiscountAccount__c != o.DiscountAccount__c && n.DiscountAccount__c > 15)){
                        if(!Approval.isLocked(n.Id)){
                            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                            req1.setSkipEntryCriteria(true);
                            req1.setObjectId(n.Id);
                            req1.setSubmitterId(UserInfo.getUserId());
                            req1.setProcessDefinitionNameOrId('ApproveAccountDiscount');
                            Approval.ProcessResult result = Approval.process(req1);
                            System.debug('Approval Process Result ' + result);
                        }
                    }
                }
            }
        }
    }
}