trigger ContentDocumentLink on ContentDocumentLink (after insert) {

    /**
    SUMMARY:
    ----------------------------------------------------------------------------------------------------------------------
    0. ----AI---        > Clone ContentDocumentLink from Synced Quote and link them to OPP
    ----------------------------------------------------------------------------------------------------------------------
    */
	if(trigger.isAfter && trigger.isInsert){
        Map<Id,ContentDocumentLink[]> cdlByQuoteLinkedIds = new Map<Id,ContentDocumentLink[]>();
        ContentDocumentLink[] cdlsToInsert = new ContentDocumentLink[]{};
        for(ContentDocumentLink n : Trigger.new){
            if(String.valueof(n.LinkedEntityId).startsWith('0Q0')){
                if(cdlByQuoteLinkedIds.containsKey(n.LinkedEntityId)){
                    ContentDocumentLink[] cdls = cdlByQuoteLinkedIds.get(n.LinkedEntityId);
                    cdls.add(n);
                    cdlByQuoteLinkedIds.put(n.LinkedEntityId, cdls);
                }else{
                    cdlByQuoteLinkedIds.put(n.LinkedEntityId, new ContentDocumentLink[]{n});
                }
            }
        }

        for(Quote q: [SELECT Id, IsSyncing, OpportunityId FROM Quote WHERE Id IN: cdlByQuoteLinkedIds.keySet()]){
            if(q.IsSyncing){
                for(ContentDocumentLink cdl : cdlByQuoteLinkedIds.get(q.Id)){
                    ContentDocumentLink oppCdl = cdl.clone(false, true, false, false);
                    oppCdl.LinkedEntityId = q.OpportunityId;
                    cdlsToInsert.add(oppCdl);
                }
            }
        }
        insert cdlsToInsert;
    }
}