trigger Invoice on Invoice__c (before insert, before update, after insert, after update){ 
	/**
SUMMARY:
----------------------------------------------------------------------------------------------------------------------
0. BIU------        > Set Opportunity ID by Order ID
1. ----AIU--		> Blank update on related Opps so CSV export takes changes
----------------------------------------------------------------------------------------------------------------------
*/
	if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
		Set<Id> ordIds = new Set<Id>();
		for(Invoice__c n : Trigger.new){
			if(n.OrderId__c != null){
				ordIds.add(n.OrderId__c);
			}
		}

		Map<Id,Order__c> oppMap = new Map<Id,Order__c>([SELECT Id, OpportunityId__c FROM Order__c WHERE Id IN:ordIds]);
		for(Invoice__c n : Trigger.new){
			Order__c ord = oppMap.get(n.OrderId__c);
			if(ord != null && ord.OpportunityId__c != null){
				n.OpportunityId__c = ord.OpportunityId__c;
			}
		}
	}

	/* 1. */
	if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){
		Set<Id> oppIds = new Set<Id>();
		for(Invoice__c n : Trigger.new){
			if(n.OpportunityId__c != null){
				oppIds.add(n.OpportunityId__c);
			}
		}

		Opportunity[] oppsToUpdate = new Opportunity[]{};
		if(!oppIds.isEmpty()){
			for(Id oppId : oppIds){
				Opportunity tmp = new Opportunity(Id = oppId);
				oppsToUpdate.add(tmp);
			}

			update oppsToUpdate;
		}
	}
}