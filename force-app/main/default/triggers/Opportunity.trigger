trigger Opportunity on Opportunity (before insert, before update, after insert, after update) {

    /**
    SUMMARY:
    ----------------------------------------------------------------------------------------------------------------------
    NOTE:
        - This trigger should be disabled in the custom settings for Home-Site User (external requests)

    0. ----AI---        > Call afterOppInsert future method
                             - Update Opp No with autonumber value - YYXXXXX (YY - last two digits of year, XXXXX - increasing autonumber)
                            - Create google drive folder for the Opportunity and link them
    1. ----AI---        > If parent Account is not synced to SAP yet, sync the record
    2. ----A-U--        > If Opportunity is set to Closed Won - create and sync Order to SAP
    3. BI-------        > Preset default Pricebook ID
    4. BI-------        > Set Opp number
    5. BIU------		> Fill close date if opp is closed won, let users change this date
    6. BIU------		> Fill Handover date, when moved to Handover stage, let users change this date
    7. ----AIU--		> Make update to related Orders so Due Date is updated (only if Realization Start is changed on opp)
    8. BIU------		> Fill Proforma Paid Date Plan based on Proforma Issued Date Plan & Proforma Payment Term (if both filled)
    9. ----AIU--		> Handle parent/child opp closing
                            - If parent (project) opp closed lost - close lost all child opps and fill avg. amount to parent
                            - If child opp Closed Won - set parent amount to won child amount and closed won, other childs to closed lost
    10. B-U----- 		> On the first filling Realization End Date is filled Realization End Plan
    11. BI------ 		> From Account fill to OPP Payment Term and Final Invoice Payment Term
    12. BIU----- 		> Fill OnSiteContact if is empty from PrimaryContact
    13. ----A-U-       	> Recalculate Project Sales Fee values when Opportunity set to Close Won
    14. ----A-U-       	> Update Project amount if Synced quote changed
    15. BIU----- 		> Fill DocuSignContact if is empty from PrimaryContact
    16. ----AI---       > Upload signed PDF files from docusign (contatining "_completed" or "CertificateOfCompletion_")
                        - DO ONLY FOR SINGLE RECORDS
    ------------------------------------------------------------------------------------------------------------------------
    */

    // GLOBAL TRIGGER DISABLE
    TriggerSettings__c userTs = TriggerSettings__c.getInstance(UserInfo.getUserID());
    TriggerSettings__c profileTs = TriggerSettings__c.getInstance(UserInfo.getProfileId());
    // Return if all or curent trigger disabled
    if ((userTs != null && (userTs.Disable_All__c || userTs.Disable_Opp_AccToSAP__c)) || (profileTs != null && (profileTs.Disable_All__c || profileTs.Disable_Opp_AccToSAP__c))) return;
    // Also invoking by future method (update by Sync Service) should be disabled
    if (System.isFuture()) {
        return;
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        /* 0. */
        for (Opportunity n : Trigger.new) {
            Hlp.afterOppInsert(n.Id);
        }
    }

    if (Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)) {
        /* 1. */ /* 9. */
        Set<Id> accIds = new Set<Id>();
        Set<Id> orderOppIds = new Set<Id>();

        Set<Id> projectClosedLostOppIds = new Set<Id>();
        Set<Id> childClosedWonOppIds = new Set<Id>();
        for (Opportunity n : Trigger.new) {
            Opportunity o = (Trigger.isUpdate) ? Trigger.oldMap.get(n.Id) : null;

            if (!n.IsAccountSynced__c && n.StageName == Cst.OPPORTUNITY_STAGE_FINALIZING && (o == null || o.StageName != Cst.OPPORTUNITY_STAGE_FINALIZING)) {
                accIds.add(n.AccountId);
            }
            // preapre closed lost project opps ids
            if (n.IsProject__c && n.IsClosed && !n.IsWon && !o.IsClosed) {
                projectClosedLostOppIds.add(n.Id);
            }
            // preapre closed won child ids
            if (!n.IsProject__c && n.ParentOpportunityId__c != null && n.IsWon && n.IsClosed && !o.IsWon && !o.IsClosed) {
                childClosedWonOppIds.add(n.Id);
            }
        }
        if (!accIds.isEmpty()) {
            Svc_AccountToSAP.syncToSAP(accIds);
        }

        if (!projectClosedLostOppIds.isEmpty() || !childClosedWonOppIds.isEmpty()) {
            // call helper class (must be future)
            Hlp.handleOppHierarchyClose(projectClosedLostOppIds, childClosedWonOppIds);
        }
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        /* 2. */ /* 13. */
        Set<Id> wonOppsQuoteIds = new Set<Id>();
        Map<Id, Id> syncedQuoteChangedProjectMap = new Map<Id, Id>();
        for (Opportunity n : Trigger.new) {
            Opportunity o = Trigger.oldMap.get(n.Id);
            if (n.StageName == Cst.OPPORTUNITY_STAGE_CLOSEDWON && o.StageName != Cst.OPPORTUNITY_STAGE_CLOSEDWON && !o.IsProject__c) {
                wonOppsQuoteIds.add(n.SyncedQuoteId);
            }
            /* 14. */
            if (n.ParentOpportunityId__c != null && n.SyncedQuoteId != null && n.SyncedQuoteId != o.SyncedQuoteId && !o.IsProject__c) {
                if (syncedQuoteChangedProjectMap.containsKey(n.ParentOpportunityId__c)) {
                    syncedQuoteChangedProjectMap.remove(n.ParentOpportunityId__c);
                }
                syncedQuoteChangedProjectMap.put(n.ParentOpportunityId__c, n.Id);
            }
        }
        Hlp.setProjectAmountByCurrentOpportunity(syncedQuoteChangedProjectMap);
        if (!wonOppsQuoteIds.isEmpty()) {
            Hlp.getDatedCZKValueFromSetQT(wonOppsQuoteIds);
            Hlp.createOrderAndSyncProducts(wonOppsQuoteIds);
        }
    }

    /* 16. */
    // DO ONLY FOR SINGLE RECORDS!
    if (Trigger.isAfter && Trigger.isUpdate && Trigger.new.size() == 1) {
        Opportunity n = Trigger.new[0];
        Opportunity o = Trigger.oldMap.get(n.Id);
        //Check if IsOrderSigned was currently checked
        if (!o.IsOrderSigned__c && n.IsOrderSigned__c) {
            // Find files with proper title related to signed orders
            ContentDocumentLink[] cdls = [
                    SELECT Id, ContentDocumentId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId = :n.Id AND (ContentDocument.Title LIKE '%_completed%' OR ContentDocument.Title LIKE 'CertificateOfCompletion_%')
            ];
            Set<Id> cdIds = new Set<Id>();
            for (ContentDocumentLink cdl : cdls) {
                cdIds.add(cdl.ContentDocumentId);
            }
            if (!cdIds.isEmpty()) {
                // Get contentDocuments with ContentDocumentLinks
                ContentDocument[] cds = [SELECT Id, LatestPublishedVersionId, (SELECT Id, LinkedEntityId FROM ContentDocumentLinks) FROM ContentDocument WHERE Id IN :cdIds];
                // If file is linked to Opportunity, call future method to upload file to GDrive
                Set<Id> docIds = new Set<Id>();
                for (ContentDocument cd : cds) {
                    if (cd.ContentDocumentLinks.isEmpty()) {
                        continue;
                    }
                    for (ContentDocumentLink cdl : cd.ContentDocumentLinks) {
                        String linkedId = cdl.LinkedEntityId;
                        if (linkedId.startsWith('006')) {
                            docIds.add(cd.LatestPublishedVersionId);
                        }
                    }
                }
                System.enqueueJob(new GoogleDriveQueueableService(n.Id, docIds));
            }
        }
    }

    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        /* 3. */
        Id stdPbId = (Test.isRunningTest()) ? Test.getStandardPricebookId() : [SELECT Id, Name FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1][0].Id;
        Opportunity[] projOpps = new Opportunity[]{
        };
        for (Opportunity opportunity : Trigger.new) {
            Opportunity o = (Trigger.isInsert) ? opportunity : Trigger.oldMap.get(opportunity.Id);
            opportunity.Pricebook2Id = stdPbId;
            /* 5. */
            if (opportunity.IsClosed && opportunity.IsWon && !o.IsClosed && !o.IsWon && opportunity.StageName == Cst.OPPORTUNITY_STAGE_CLOSEDWON) {
                opportunity.CloseDate = System.today();
            }
            /* 6. */
            if (opportunity.StageName == Cst.OPPORTUNITY_STAGE_HANDOVER && opportunity.StageName != o.StageName) {
                opportunity.HandoverDate__c = System.today();
                if (opportunity.ParentOpportunityId__c != null) {
                    projOpps.add(new Opportunity(Id = opportunity.ParentOpportunityId__c, HandoverDate__c = opportunity.HandoverDate__c, StageName = Cst.OPPORTUNITY_STAGE_HANDOVER));
                }
            }
            /* 7. */
            opportunity.OrderDueDate__c = opportunity.RealizationStartDate__c;
            /* 8. */
            if (opportunity.ProformaIssuedDatePlan__c != null && opportunity.PaymentTerm__c != null) {
                opportunity.ProformaPaidDatePlan__c = opportunity.ProformaIssuedDatePlan__c.addDays(Integer.valueOf(opportunity.PaymentTerm__c));
            }
            /* 12. */
            if (String.isBlank(opportunity.OnSiteContactId__c) && !String.isBlank(opportunity.PrimaryContact__c)) {
                opportunity.OnSiteContactId__c = opportunity.PrimaryContact__c;
            }
            /* 15. */
            if (String.isBlank(opportunity.DocuSignContact__c) && !String.isBlank(opportunity.PrimaryContact__c)) {
                opportunity.DocuSignContact__c = opportunity.PrimaryContact__c;
            }
        }
        update projOpps;
    }

    /* 4. */
    // Do ONLY for SINLGE records!
    if (Trigger.isBefore && Trigger.isInsert && Trigger.new.size() == 1) {

        // For new Standard Opp - get last Opp Number
        // Fill OpportunityNo__c in YYXXXXX.00 format (YY - last two digits of current year, XXXXX - increasing serial number NumericalSeries__c, 00 - OpportunityNumber__c in project - default 01)
        String currYear = String.valueOf(Date.today().year()).substring(2, 4);
        String qCurrYear = currYear + '%';

        Opportunity n = Trigger.new[0];
        if (!n.IsProject__c) { // Project values are filed in QA_OppCreateController
            if (n.ParentOpportunityId__c == null) {
                Opportunity[] lastOpps = [SELECT Id, Name, OpportunityNo__c, OpportunityNumber__c, NumericalSeries__c, ProjectNumber__c FROM Opportunity WHERE OpportunityNo__c LIKE :qCurrYear ORDER BY NumericalSeries__c DESC NULLS LAST LIMIT 1];
                n.NumericalSeries__c = (lastOpps.isEmpty()) ? 0 : lastOpps[0].NumericalSeries__c + 1; // Increase
                n.ProjectNumber__c = currYear + String.valueOf(n.NumericalSeries__c).leftPad(5, '0');
                n.OpportunityNumber__c = 1;
                n.OpportunityNo__c = n.ProjectNumber__c + '.' + String.valueOf(n.OpportunityNumber__c).leftPad(2, '0');
            } else {
                Opportunity parent = [SELECT Id, Name, OpportunityNo__c, OpportunityNumber__c, NumericalSeries__c, ProjectNumber__c, (SELECT Id, OpportunityNumber__c FROM ChildOpportunities__r ORDER BY OpportunityNumber__c DESC) FROM Opportunity WHERE Id = :n.ParentOpportunityId__c LIMIT 1][0];
                // Same as parent / opp on same level
                n.NumericalSeries__c = parent.NumericalSeries__c;
                n.ProjectNumber__c = parent.ProjectNumber__c;
                // Set number by previous records
                n.OpportunityNumber__c = (parent.ChildOpportunities__r.size() > 0) ? parent.ChildOpportunities__r[0].OpportunityNumber__c + 1 : 1; // Increase or set as first
                n.OpportunityNo__c = n.ProjectNumber__c + '.' + String.valueOf(n.OpportunityNumber__c).leftPad(2, '0');
            }
        }
    }

    /* 5. */
    if (Trigger.isBefore) {
        for (Opportunity opportunity : Trigger.new) {
            if (opportunity.Pricebook2Id == null) {
                opportunity.Pricebook2Id = Hlp.getStandardPriceBookId();
            }
        }

        /* 10 */
        if (Trigger.isUpdate) {
            for (Opportunity opportunity : Trigger.new) {
                Opportunity oldOpportunity = Trigger.oldMap.get(opportunity.Id);
                if (opportunity.RealizationEndDate__c != null && oldOpportunity.RealizationEndDate__c == null && oldOpportunity.RealizationEndPlan__c == null) {
                    opportunity.RealizationEndPlan__c = opportunity.RealizationEndDate__c;
                }
            }
        }

        /* 11. */
        if (Trigger.isInsert) {
            Set<Id> accountIds = new Set<Id>();
            for (Opportunity n : Trigger.new) {
                accountIds.add(n.AccountId);
            }

            Map<Id, Account> relatedAccountsMap = new Map<Id, Account>([SELECT Id, ProformaPaymentTerm__c, FinalInvoicePaymentTerm__c, Invoicing_Department_Acc__c, ProformaPercent_Acc__c FROM Account WHERE Id IN :accountIds]);
            for (Opportunity opportunity : Trigger.new) {
                if (relatedAccountsMap.containsKey(opportunity.AccountId)) {
                    opportunity.PaymentTerm__c = relatedAccountsMap.get(opportunity.AccountId).ProformaPaymentTerm__c;
                    opportunity.FinalInvoicePaymentTerm__c = relatedAccountsMap.get(opportunity.AccountId).FinalInvoicePaymentTerm__c;
                    opportunity.Invoicing_Department__c = relatedAccountsMap.get(opportunity.AccountId).Invoicing_Department_Acc__c;
                    opportunity.ProformaPercent__c = relatedAccountsMap.get(opportunity.AccountId).ProformaPercent_Acc__c;
                }
            }
        }
    }
}