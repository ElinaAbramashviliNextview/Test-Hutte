trigger Order on Order__c (after insert, before update)  {
/**
SUMMARY:
----------------------------------------------------------------------------------------------------------------------
0. ---B--U--        > Sync Orders to SAP if FORCE status
1. ----AI---        > Call after insert actions for Order
----------------------------------------------------------------------------------------------------------------------
*/

	// GLOBAL TRIGGER DISABLE
	TriggerSettings__c userTs = TriggerSettings__c.getInstance( UserInfo.getUserID() );
	TriggerSettings__c profileTs = TriggerSettings__c.getInstance( UserInfo.getProfileId() );
	// Return if all or curent trigger disabled
	if((userTs != null && (userTs.Disable_All__c || userTs.Disable_OrderToSAP__c)) || (profileTs != null && (profileTs.Disable_All__c || profileTs.Disable_OrderToSAP__c))) return;

	if(Trigger.isBefore && Trigger.isUpdate){
		/* 0. */
		Set<Id> recIds = new Set<Id>();
		for(Order__c n : Trigger.new){
			if(n.SyncStatus__c == Cst.SYNC_STATUS_FORCE){
				recIds.add(n.Id);
				n.SyncStatus__c = Cst.SYNC_STATUS_SYNCING;
			}
		}
		if(!recIds.isEmpty()){
			System.enqueueJob(new Svc_OrderToSAP(recIds));
		}
	}

	if(Trigger.isAfter && Trigger.isInsert){
		/* 1. */
		for(Order__c n : Trigger.new){
			// Create event in google calendar
			System.enqueueJob(new Svc_EventToGC(n.Id));
		}
	}
}