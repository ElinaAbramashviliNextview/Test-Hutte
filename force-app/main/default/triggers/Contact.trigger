trigger Contact on Contact (before insert, after insert, before update) {

/**
SUMMARY:
----------------------------------------------------------------------------------------------------------------------
0. ----AIU--        > Sync Contact to SAP for synced Accounts (or if FORCE Sync)
	NOTE:
		- This trigger should be disabled for Home-Site User (external requests) in the custom invoked by external system
----------------------------------------------------------------------------------------------------------------------
*/

    // GLOBAL TRIGGER DISABLE
    TriggerSettings__c userTs = TriggerSettings__c.getInstance( UserInfo.getUserID() );
    TriggerSettings__c profileTs = TriggerSettings__c.getInstance( UserInfo.getProfileId() );
    // Return if all or curent trigger disabled
    if((userTs != null && (userTs.Disable_All__c || userTs.Disable_Con_AccToSAP__c)) || (profileTs != null && (profileTs.Disable_All__c || profileTs.Disable_Con_AccToSAP__c))) return;

    // Also invoking by future method (update by Sync Service) should be disabled
    if(System.isFuture()){ return; }

	/* 0. */
	Set<Id> conIds = new Set<Id>();
	for(Contact n : Trigger.new){
		// Before Insert
		if(Trigger.isBefore && Trigger.isInsert && n.IsAccountSynced__c){
			n.SyncStatus__c = Cst.SYNC_STATUS_SYNCING;
		}

		// After Insert
		if(Trigger.isAfter && Trigger.isInsert && n.IsAccountSynced__c && n.SyncStatus__c == Cst.SYNC_STATUS_SYNCING){
			conIds.add(n.Id);
		}

		if(Trigger.isBefore && Trigger.isUpdate){
			if(n.IsAccountSynced__c){
				conIds.add(n.Id);
				n.SyncStatus__c = Cst.SYNC_STATUS_SYNCING;
			}else if(n.SyncStatus__c == Cst.SYNC_STATUS_FORCE){
				n.addError('Parent Account must be synced.');
			}
		}
	}
	if(!conIds.isEmpty()){
		Svc_ContactToSAP.syncToSAP(conIds);
	}
}