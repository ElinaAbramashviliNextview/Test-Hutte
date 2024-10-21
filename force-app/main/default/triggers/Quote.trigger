trigger Quote on Quote (before insert, before update, after insert, after update)  {
    private static final String AP_FREE_SHIPPING = 'Free_Shipping_Quote_Approval_Process';
    private static final String AP_QUOTE_DISCOUNT = 'DiscountQuoteApprovalProcess';
/**
SUMMARY:
----------------------------------------------------------------------------------------------------------------------
0. BI-------        > Set Quote name by Opp Name, No and Quote version
1. B-U------        > Set PrintedDate__c and SentDate__c by Quote Status
2. ----AU---        > Set Quote Status is "Quoted" - set Opportunity Stage also as "Quoted"
3. ----AU---        > Prevent record edit if status is Printed or Quoted
4. BIU------        > Set default PriceBook ID if not filled in
5. BIU------        > Set Need Approve checkbox by discount on Account and QLI
6. ----AIU--        > Start Approval Process
7. ----AI---        > Star syncing with Opportunity immediatelly after insert
8. BIU------        > Send ShippingAddress fields from Synced Quote to Opportunity
9. ----A-U--        > Delete Content Document Link from OPP when Stop Sync Quote
10. ----A-U--       > Create Content Document Link from Synced Quote when Start Sync
----------------------------------------------------------------------------------------------------------------------
*/
 
    // GLOBAL TRIGGER DISABLE
    TriggerSettings__c userTs = TriggerSettings__c.getInstance( UserInfo.getUserID() );
    TriggerSettings__c profileTs = TriggerSettings__c.getInstance( UserInfo.getProfileId() );
    // Return if all or curent trigger disabled
    if((userTs != null && (userTs.Disable_All__c || userTs.DisableQuote__c)) || (profileTs != null && (profileTs.Disable_All__c || profileTs.DisableQuote__c))) return;
    
        /* 5. */
    if(Trigger.isBefore){
        ApprovalSettings__c profileAS = ApprovalSettings__c.getInstance(UserInfo.getProfileId());
        Boolean hasFreeShipping = isFreeShipping(Trigger.new);
        if(profileAS.NeedApprove__c){
            Set<Id> quoteIdsToApprove = new Set<Id>();
            Map<Id,Id> accIdByQuoteId = new Map<Id,Id>();
            Map<Id,Decimal> accDiscByQuoteId = new Map<Id,Decimal>();
            for(Quote n : Trigger.new){
                accIdByQuoteId.put(n.Id, n.AccountId);
                Boolean wasApproved = checkIfQuoteWasApproved(n, Trigger.oldMap);
                if(hasFreeShipping && !wasApproved) {
                    n.DiscountReason__c = n.Language__c == 'cs' ? Label.AP_Discount_Reason_for_Free_Shipping_CZ : Label.AP_Discount_Reason_for_Free_Shipping;
                    quoteIdsToApprove.add(n.Id);
                } 
            }

            Account[] accs = [SELECT Id, DiscountAccount__c, OldAccountDiscount__c FROM Account WHERE Id IN: accIdByQuoteId.values()];
            for(Account acc : accs){
                Decimal accDisc = 0;
                if(Approval.isLocked(acc.Id)){
                    accDisc = (acc.OldAccountDiscount__c != null && acc.OldAccountDiscount__c > 0) ? acc.OldAccountDiscount__c + 0 : 5;
                }else{
                    accDisc = (acc.DiscountAccount__c != null && acc.DiscountAccount__c > 0) ? acc.DiscountAccount__c + 0 : 5;
                }
                for(String qId : accIdByQuoteId.keySet()){
                    if(accIdByQuoteId.get(qId) == acc.Id){
                        accDiscByQuoteId.put(qId, accDisc);
                    }
                }
            }

            QuoteLineItem[] qlis = [SELECT Id, QuoteId, Discount, RowTotalDiscount__c FROM QuoteLineItem WHERE QuoteId IN: accDiscByQuoteId.keySet()];

            for(QuoteLineItem qli: qlis){
                if(qli.RowTotalDiscount__c != null && qli.RowTotalDiscount__c.setScale(2) > accDiscByQuoteId.get(qli.QuoteId)){
                    quoteIdsToApprove.add(qli.QuoteId);
                }
            }

            for(Quote n: Trigger.new){
                if(n.IsApproved__c){
                    continue;
                }
                if(quoteIdsToApprove.contains(n.Id) && !n.IsRecall__c){
                    n.NeedApprove__c = true;
                    n.Status = 'For Approve';
                }else if(!quoteIdsToApprove.contains(n.Id)){
                    n.NeedApprove__c = false;
                }
            }
        }

        /* 0. */
        if(Trigger.isInsert){
            Set<Id> oppIds = new Set<Id>();
            for(Quote n : Trigger.new){
                oppIds.add(n.OpportunityId);
            }

            Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([SELECT Id, Name, OpportunityNo__c, QuotesCount__c, Account.BillingAddress FROM Opportunity WHERE Id IN:oppIds]);
            for(Quote n : Trigger.new){
                Opportunity opp = oppMap.get(n.OpportunityId);
                Decimal ver = opp.QuotesCount__c+1; // We don't expect bulk insert, but if so - all quotes for same Opp will have same version number!
                n.QuoteNo__c = opp.OpportunityNo__c + '.' + ver;
                n.Name = opp.Name + '.'+ n.QuoteNo__c;
                if(n.Language__c == 'cs'){
                    n.Description__c = System.Label.QuotePdf_AdditionalInfoCS + System.Label.QuotePdf_AdditionalInfoCSPart2 + System.Label.QuotePdf_AdditionalInfoCSPart3 +
                    System.Label.QuotePdf_AdditionalInfoCSPart4;
                }else if(n.Language__c == 'en_US'){
                    n.Description__c = System.Label.QuotePdf_AdditionalInfoEN + System.Label.QuotePdf_AdditionalInfoENPart2 + System.Label.QuotePdf_AdditionalInfoENPart3 +
                    System.Label.QuotePdf_AdditionalInfoENPart4;
                }
            }
        }

        /* 1. */
        if(Trigger.isUpdate){
            for(Quote n : Trigger.new){
                Quote o = Trigger.oldMap.get(n.Id);
                if(o.Status != Cst.QUOTE_STATUS_PRINTED && n.Status == Cst.QUOTE_STATUS_PRINTED){
                    n.PrintedDate__c = Date.today();
                    n.ExpirationDate = Date.today().addMonths(1);
                } else if(o.Status != Cst.QUOTE_STATUS_QUOTED && n.Status == Cst.QUOTE_STATUS_QUOTED){
                    n.SentDate__c = Date.today();
                }
            }
        }

        /* 4. */
        for(Quote n : Trigger.new){
            if(n.Pricebook2Id == null){
                n.Pricebook2Id = Hlp.getStandardPriceBookId();
            }
        }
    }

    /* 2. */
    if(Trigger.isAfter && Trigger.isUpdate){

        Set<Id> oppIds = new Set<Id>();
        Map<Id,Id> oppIdsByStopSyncedQuoteIds = new Map<Id,Id>();
        Map<Id,Id> oppIdsByStartSyncedQuoteIds = new Map<Id,Id>();
        for(Quote n : Trigger.new){
            Quote o = Trigger.oldMap.get(n.Id);
            
            /* 2. 
            if(o.Status == Cst.QUOTE_STATUS_PRINTED && n.Status == Cst.QUOTE_STATUS_QUOTED && !checkIfChanged(o, n)){
                oppIds.add(n.OpportunityId);
            /* 3.
            } else if((o.Status == Cst.QUOTE_STATUS_PRINTED && n.Status == Cst.QUOTE_STATUS_PRINTED && checkIfChanged(o, n)) || (o.Status == Cst.QUOTE_STATUS_PRINTED && n.Status != Cst.QUOTE_STATUS_QUOTED && checkIfChanged(o, n))){
                n.addError('"Printed"" or "Quoted" Quote is locked for edit - it can be only marked as Quoted');
            }
			*/
            if (!n.IsSyncing && (
                (o.Status == Cst.QUOTE_STATUS_PRINTED && n.Status == Cst.QUOTE_STATUS_PRINTED && checkIfChanged(o, n)) || 
                (o.Status == Cst.QUOTE_STATUS_PRINTED && n.Status != Cst.QUOTE_STATUS_QUOTED && checkIfChanged(o, n))
      	    )) {
          		n.addError('"Printed" or "Quoted" Quote is locked for edit - it can be only marked as Quoted');
      		}

            /* 9.*/
            if(o.IsSyncing && !n.IsSyncing){
                oppIdsByStopSyncedQuoteIds.put(n.Id, n.OpportunityId);
            }

            /* 10.*/
            if(!o.IsSyncing && n.IsSyncing){
                oppIdsByStartSyncedQuoteIds.put(n.Id, n.OpportunityId);
            }
        }

        /* 2. 
        Opportunity[] oppsToUpdate = new Opportunity[]{};
        for(Id oId : oppIds){
            oppsToUpdate.add(new Opportunity(Id=oId,StageName=Cst.OPPORTUNITY_STAGE_QUOTED));
        }
        update oppsToUpdate; */

        /* 9.*/
        if(oppIdsByStopSyncedQuoteIds.size() > 0){
            Set<Id> cdIds = new Set<Id>();
            ContentDocumentLink[] cdlsStopSync = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN: oppIdsByStopSyncedQuoteIds.keySet()];
            for(ContentDocumentLink cdl : cdlsStopSync){
                cdIds.add(cdl.ContentDocumentId);
            }
            ContentDocumentLink[] cdlToDelete = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE ContentDocumentId IN: cdIds AND LinkedEntityId IN: oppIdsByStopSyncedQuoteIds.values()];
            delete cdlToDelete;
        }

        /* 10. */
        if(oppIdsByStartSyncedQuoteIds.size() > 0){
            ContentDocumentLink[] cdlsToInsert = new ContentDocumentLink[]{};
            ContentDocumentLink[] cdlsStartSync = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN: oppIdsByStartSyncedQuoteIds.keySet()];
            for(ContentDocumentLink cdl : cdlsStartSync){
                ContentDocumentLink oppCdl = cdl.clone(false, true, false, false);
                oppCdl.LinkedEntityId = oppIdsByStartSyncedQuoteIds.get(cdl.LinkedEntityId);
                cdlsToInsert.add(oppCdl);
            }
            insert cdlsToInsert;
        }
    }

    /* 6. */
    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){
        ApprovalSettings__c profileAS = ApprovalSettings__c.getInstance(UserInfo.getProfileId());
        System.debug('Proofile ' + profileAS.NeedApprove__c);
        System.debug('Settings ' + profileAS);

        /* Check Free_Shipping__c (TRUE - initiate AP) */
        Boolean hasFreeShipping = isFreeShipping(Trigger.new);

        if(profileAS.NeedApprove__c || hasFreeShipping ){
            for(Quote n: Trigger.new){
                if(Approval.isLocked(n.Id)) continue;
                Boolean wasApproved = checkIfQuoteWasApproved(n, Trigger.oldMap);
                Boolean shouldBeApprovedDueToCustomSettings = n.NeedApprove__c  && !n.IsApproved__c && !Approval.isLocked(n.Id)  && !n.IsRecall__c;
                Boolean shouldBeApprovedDueToFreeShipping = hasFreeShipping && !wasApproved && !Approval.isLocked(n.Id) && !n.IsRecall__c;
                
                if(shouldBeApprovedDueToCustomSettings || shouldBeApprovedDueToFreeShipping){   
                    Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                    req1.setObjectId(n.Id);
                    req1.setSubmitterId(UserInfo.getUserId());
                    String approvalName = hasFreeShipping ? AP_FREE_SHIPPING : AP_QUOTE_DISCOUNT;
                    system.debug('approvalName: ' + approvalName);
                    req1.setProcessDefinitionNameOrId(approvalName);
                    req1.setSkipEntryCriteria(true);
                    Approval.ProcessResult result = Approval.process(req1);
                    System.debug('Approval Process Result ' + result);

                    if(hasFreeShipping) {
                        ToastNotificationEvent__e event = new ToastNotificationEvent__e(
                            Message__c = 'Quote has been sent for Approval due to 100% discount on shipping cost.',
                            RecordId__c = n.Id
                        );
                       // EventBus.publish(event);
                    }

                }
            }
        }

        /* 8. */
        Set<Id> oppIds = new Set<Id>();
        for(Quote n: Trigger.new){
            oppIds.add(n.OpportunityId);
        }

        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([SELECT Id, City__c, Street__c, State__c, Country__c, PostalCode__c FROM Opportunity WHERE Id IN: oppIds]);
        Opportunity[] opps = new Opportunity[]{};
        for(Quote n: Trigger.new){
            Opportunity opp = oppMap.get(n.OpportunityId);
            if(n.IsSyncing && n.IsSendAddressToOpportunity__c && (n.ShippingStreet != opp.Street__c || n.ShippingCity != opp.City__c || n.ShippingPostalCode != opp.PostalCode__c || n.ShippingState != opp.State__c || n.ShippingCountry != opp.Country__c)){
                Boolean isAnyFieldUpdated = false;
                if (Hlp.areValuesDifferent(opp.Street__c, n.ShippingStreet, true)) {
                    opp.Street__c = n.ShippingStreet;
                    isAnyFieldUpdated = true;
                }

                if (Hlp.areValuesDifferent(opp.City__c, n.ShippingCity, true)) {
                    opp.City__c = n.ShippingCity;
                    isAnyFieldUpdated = true;
                }

                if (Hlp.areValuesDifferent(opp.State__c, n.ShippingState, true)) {
                    opp.State__c = n.ShippingState;
                    isAnyFieldUpdated = true;
                }

                if (Hlp.areValuesDifferent(opp.PostalCode__c, n.ShippingPostalCode, true)) {
                    opp.PostalCode__c = n.ShippingPostalCode;
                    isAnyFieldUpdated = true;
                }

                if (Hlp.areValuesDifferent(opp.Country__c, n.ShippingCountry, true)) {
                    opp.Country__c = n.ShippingCountry;
                    isAnyFieldUpdated = true;
                }

                if (isAnyFieldUpdated) {
                    opps.add(opp);
                }
            }
        }
        if (opps.size() > 0) {
            List<Database.SaveResult> saveResult = Database.update(opps, false);
            for (Database.SaveResult singleResult : saveResult) {
                if (!singleResult.isSuccess()) {
                    new AsyncLogService.LogBuilder()
                        .setRecordId(singleResult.getId())
                        .setMandatoryFields(AsyncLogService.TYPE_ERROR, Quote.class.getName(), 'QuoteTrigger')
                        .setErrorFields('Error while trying to update opportunity Address details based on Quote', singleResult.errors[0].getMessage(), null)
                        .log();
                }
            }
        }
    }

    /* 7. */
    // SXC: Commented out - sync after SavePDF
    /*if(Trigger.isAfter && Trigger.isInsert){
        Map<Id,Id> quoteOppIds = new Map<Id,Id>();
        for(Quote n : Trigger.new){
            quoteOppIds.put(n.Id,n.OpportunityId);
        }
        Hlp.afterQuoteInsert(quoteOppIds);
    }*/

    // Compare old and new values to check if some of them has changed
    private static Boolean checkIfChanged(Quote o, Quote n){
        SObjectType quoteType = Schema.getGlobalDescribe().get('Quote');
        Map<String,Schema.SObjectField> quoteFields = quoteType.getDescribe().fields.getMap();
        for(SObjectField sof : quoteFields.values()){
            Schema.DescribeFieldResult f = sof.getDescribe();
            String fName = f.getName();
            // Skip Status and fields which are not editable
            if(fName != 'Status' && f.isAccessible() && f.isUpdateable() && n.get(fName) != o.get(fName)){
                return true;
            }
        }
        return false;
    }

    private static Boolean isFreeShipping(List<Quote> quotes) {
        Boolean hasFreeShipping = false;
        for (Quote q : Trigger.new) {
            if(q.x_Qli_Item_Free_Shipping__c == true) {
                hasFreeShipping = true;
                break;
            }
        }
        return hasFreeShipping;
    }

    private static Boolean checkIfQuoteWasApproved(Quote newQuote, Map<Id, Quote> oldMap) {
        if(oldMap == null) return false;
        return oldMap.containsKey(newQuote.Id) && oldMap.get(newQuote.Id).Status == 'Approved';
    }

}