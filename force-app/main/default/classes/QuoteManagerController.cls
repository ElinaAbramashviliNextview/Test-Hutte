public without sharing class QuoteManagerController {
    private static final String TRANSPORT_PRODUCT_NAME = '%Doprava%';
    private static final String TRANSPORT_PRODUCT_NAME_ENG = '%Transport%';
    @AuraEnabled
    public static QuoteManagerMdl auraGetData(Id quoteId) {

        QuoteManagerMdl qmm = new QuoteManagerMdl();
        Map<Id,Mdl.QuoteLineMdl> qliModelMap = new Map<Id,Mdl.QuoteLineMdl>();

        qmm.qt = [SELECT Name, ExpirationDate, Status, TotalPrice__c, CurrencyIsoCode, Subtotal__c, QuoteDiscount__c, Discount, Language__c, QuoteDiscountValue__c,
                ShippingCountry, ShippingStreet, ShippingCity, ShippingPostalCode, AccountId, IsApproved__c, NeedApprove__c, QuoteTotalDiscount__c, DiscountReason__c,
                Opportunity.StageName, Opportunity.IsClosed, OpportunityId, Pricebook2.Name, Pricebook2Id, ProjectSalesFee__c, ProjectSalesFeeValue__c, x_Qli_Item_Free_Shipping__c
                FROM Quote WHERE Id = :quoteId LIMIT 1];


        qmm.quoteIsLocked = Approval.isLocked(qmm.qt.Id);

        qmm.psfs = [SELECT Name, Reward__c, LowerRange__c, HigherRange__c, Id FROM ProjectSalesFee__c ORDER BY LowerRange__c ASC];

        Account acc = [SELECT Id, DiscountAccount__c, OldAccountDiscount__c FROM Account WHERE Id =: qmm.qt.AccountId];
        if(Approval.isLocked(acc.Id)){
            qmm.accountDiscount = (acc.OldAccountDiscount__c != null && acc.OldAccountDiscount__c > 0) ? acc.OldAccountDiscount__c + 0 : 0;
        }else{
            qmm.accountDiscount = (acc.DiscountAccount__c != null && acc.DiscountAccount__c > 0) ? acc.DiscountAccount__c + 0 : 0;
        }

        qmm.needAppprove = ApprovalSettings__c.getInstance(UserInfo.getProfileId()).NeedApprove__c ? true : ApprovalSettings__c.getInstance(UserInfo.getUserId()).NeedApprove__c;

        if(qmm.qt.Status == Cst.QUOTE_STATUS_PRINTED || qmm.qt.Status == Cst.QUOTE_STATUS_QUOTED){qmm.isQuotedPrinted = true;}

        QuoteLineItem[] qlis = [SELECT Id, ProductName__c, ListPrice, Quantity, Discount, TotalPrice, ParentId__c, QuoteId, UnitPrice, RowDiscount__c, RowTotalPrice__c, UnitPrice__c,
                                ProductDescriptionEN__c, ProductDescriptionCZ__c, IsDefault__c, QuantityUnitOfMeasure__c, LineCost__c, RowTotalDiscount__c, RowNumber__c, RelatedOptionalEquipment__c,                      
                                PricebookEntry.Product2Id, PricebookEntry.Product2.Name, PricebookEntry.Product2.Description, PricebookEntry.Product2.Type__c,
                                PricebookEntry.Product2.QuantityUnitOfMeasure, PricebookEntry.Product2.BusinessName__c, PricebookEntry.Product2.UnitCost__c, IsShowInQuotePDF__c
                                FROM QuoteLineItem WHERE QuoteId =: quoteId AND IsTransport__c = false ORDER BY RowNumber__c ASC];

        QuoteLineItem[] qliTransports = [SELECT Id, TC_AccommodationCost__c, TC_AssemblyCost__c, TC_MaterialShippingCost__c, TC_ShippingCost__c, IsTransport__c, RowTotalPrice__c, QuoteId,
                                        Quantity, PricebookEntry.Product2Id, UnitPrice, UnitPrice__c, PricebookEntry.Product2.Name, ProductName__c, LineCost__c,Free_Shipping__c
                                        FROM QuoteLineItem WHERE QuoteId =: quoteId AND IsTransport__c = true];
        system.debug('qliTransports__ ' + qliTransports);
        PricebookEntry[] transports = [SELECT Product2Id, Product2.Name, Id FROM PricebookEntry WHERE Product2Id =: Cst.TRANSPORT_ID AND CurrencyIsoCode =: qmm.qt.CurrencyIsoCode];

        if(qliTransports.size() > 0){
            qmm.qliTransport = qliTransports[0];
        }else{
            Id prodTransportId;
            Id pbeTransportId;
            String prodTransportName = '';
            if(transports.size() > 0){
                prodTransportId = transports[0].Product2Id; 
                prodTransportName = transports[0].Product2.Name;
                pbeTransportId = transports[0].Id;
            }
            qmm.qliTransport = new QuoteLineItem(
                                TC_AccommodationCost__c = 0, 
                                TC_AssemblyCost__c = 0, 
                                TC_MaterialShippingCost__c = 0, 
                                TC_ShippingCost__c = 0, 
                                IsTransport__c = true, 
                                RowTotalPrice__c = 0,
                                QuoteId = quoteId,
                                Quantity = 1,
                                Product2Id = prodTransportId,
                                PricebookEntryId = pbeTransportId,
                                UnitPrice = 1,
                                UnitPrice__c = 1,
                                ProductName__c = prodTransportName,
                                LineCost__c = 0
                                );
        }

        Set<Id> qliIds = new Set<Id>();
        for(QuoteLineItem qli : qlis){  
            qliIds.add(qli.Id);
            System.debug('QLI Row Number ' + qli.RowNumber__c);
            System.debug('QLI Name ' + qli.PricebookEntry.Product2.Name);
        }

        QLIDescription__c[] qliDescs = [SELECT Id, QuoteLineItemId__c, TitleCZ__c, TitleEN__c, DescriptionCZ__c, DescriptionEN__c, RowNumber__c, Name
                                        FROM QLIDescription__c WHERE QuoteLineItemId__c IN: qliIds ORDER BY RowNumber__c];

        // TODO: předělat do nested query
        QuoteLineSubItem__c[] qlsis = [SELECT Id, ProductName__c, Quantity__c, QuoteLineItemId__c, Description__c, Product2Id__c, IsVisible__c, IsEditable__c, IsTemplateProduct__c, IsVisibleOnPDF__c, Position__c,
                                        ProductDescriptionCZ__c, ProductDescriptionEN__c, 
                                        Product2Id__r.UnitCost__c, QuantityUnitOfMeasure__c, Product2Id__r.Name, Product2Id__r.QuantityUnitOfMeasure, Product2Id__r.BusinessName__c, Product2Id__r.BusinessNameEN__c,
                                        Product2Id__r.Specification__c
                                        FROM QuoteLineSubItem__c WHERE QuoteLineItemId__c IN: qliIds];
        
        for(QuoteLineItem qli : qlis){
            Mdl.QuoteLineMdl qlm = new Mdl.QuoteLineMdl();
            qlm.qliParent = qli;
            qlm.qliParentId = qli.Id;
            for(QLIDescription__c qliDesc : qliDescs){
                if(qli.Id == qliDesc.QuoteLineItemId__c ){
                    qlm.qliDescriptions.add(qliDesc);
                }
            }
            for(QuoteLineSubItem__c qlsi: qlsis){
                if(qli.Id == qlsi.QuoteLineItemId__c ){
                    qlm.qliChilds.add(qlsi);
                }
            }
            qmm.qlis.add(qlm);
        }   
        qmm.specPicklist = Hlp.getPickVals('Product2', 'Specification__c');
        qmm.specPicklist.add(0, new Mdl.PickVal('0', '--None--'));

        qmm.prodFamilies = Hlp.getPickVals('Product2', 'Family');
        qmm.prodFamilies.add(0, new Mdl.PickVal('0', '--None--'));

        return qmm;
    }

    @AuraEnabled
    public static Mdl.SaveMdl auraSave(String qlmsToUpsert, Mdl.QuoteLineMdl[] qlmsToDel, String stingQuote, String qliTransportUpsert, Boolean qliTransportFree, Decimal shippmentTotal){
        // System.debug('QLI to Upsert ' + qlmsToUpsert);
        // System.debug('QLI to Delete ' + qlmsToDel);
        Mdl.SaveMdl sm = new Mdl.SaveMdl();
        try{
            Mdl.QuoteLineMdl[] qlmsUpsert = (Mdl.QuoteLineMdl[])JSON.deserialize(qlmsToUpsert, Mdl.QuoteLineMdl[].class);
            qlmsUpsert = auraGetLineCost(qlmsUpsert);
    
            Quote currQuote = (Quote)JSON.deserialize(stingQuote, Quote.class);
            QuoteLineItem qliTransToUpsert = (QuoteLineItem)JSON.deserialize(qliTransportUpsert, QuoteLineItem.class);
            system.debug('qliTransToUpsert ' + qliTransToUpsert);
            // System.debug('QLI to Upsert after deserialize ' + qlmsUpsert);
            QuoteLineItem[] qlisToUpsert = new QuoteLineItem[]{};
            QuoteLineItem[] qlisOptToUpsert = new QuoteLineItem[]{};
            QuoteLineSubItem__c[] qlsisToUpsert = new QuoteLineSubItem__c[]{};
            QLIDescription__c[] qliDescsToUpsert = new QLIDescription__c[]{};
            
            Set<Id> setQliIdToDel = new Set<Id>();
            QuoteLineSubItem__c[]qlsisToDelete = new QuoteLineSubItem__c[]{};
            QuoteLineItem[] qlisToDelete = new QuoteLineItem[]{};
            QLIDescription__c[] qliDescsToDelete = new QLIDescription__c[]{};
    
            Map<Id,Id> bomBundleBundleItem = new Map<Id,Id>();
            Set<Id> productIds = new Set<Id>();
    
            // Set to 0 if Quote contains only Transport
            if(currQuote.QuoteTotalDiscount__c == null){
                currQuote.QuoteTotalDiscount__c = 0;
            }
            // Quote
            Quote qt = new Quote(Id = currQuote.Id,
                QuoteDiscount__c = currQuote.QuoteDiscount__c,
                Subtotal__c = currQuote.Subtotal__c,
                TotalPrice__c = currQuote.TotalPrice__c,
                QuoteDiscountValue__c = currQuote.QuoteDiscountValue__c,
                IsRecall__c = false,
                QuoteTotalDiscount__c = currQuote.QuoteTotalDiscount__c,
                DiscountReason__c = currQuote.DiscountReason__c,
                ProjectSalesFee__c = currQuote.ProjectSalesFee__c,
                ProjectSalesFeeValue__c = currQuote.ProjectSalesFeeValue__c,
                x_Qli_Item_Free_Shipping__c = currQuote.x_Qli_Item_Free_Shipping__c
                );
            update qt;
            system.debug('GT UPDATED!!!');

            Integer rowNumber = 0;
            for(Mdl.QuoteLineMdl qlm : qlmsUpsert){
                // System.debug('Parent ' + qlm.qliParent.UnitPrice);
                qlm.qliParent.RowNumber__c = ++rowNumber;
                // System.debug('Parent Row Number ' + qlm.qliParent.RowNumber__c);
                if(String.isBlank(qlm.qliParent.RelatedOptionalEquipment__c)){
                    qlisToUpsert.add(qlm.qliParent);
                }else{
                    qlisOptToUpsert.add(qlm.qliParent);
                }
                // System.debug('Parent ProductId ' + qlm.qliParent.Product2Id);
                productIds.add(qlm.qliParent.Product2Id);
            }
            upsert qlisToUpsert;
    
            if(qlisToUpsert.size() > 0){
                for(Mdl.QuoteLineMdl qlm : qlmsUpsert){
                    if(qlisOptToUpsert.size() > 0){
                        for(QuoteLineItem qliOpt : qlisOptToUpsert){
                            System.debug('qlm.qliParentId ' + qlm.qliParentId);
                            System.debug('qliOpt.RelatedOptionalEquipment__c ' + qliOpt.RelatedOptionalEquipment__c);
                            if(String.valueOf(qliOpt.RelatedOptionalEquipment__c) == qlm.qliParentId){
                                qliOpt.RelatedOptionalEquipment__c = qlm.qliParent.Id;
                                System.debug('qliOpt.RelatedOptionalEquipment__c ' + qliOpt.RelatedOptionalEquipment__c);
                            }
                        }
                    }
                }
            }
            upsert qlisOptToUpsert;
    
    
            if(qlisToUpsert.size() > 0){
                for(Mdl.QuoteLineMdl qlm : qlmsUpsert){
                    for(QuoteLineSubItem__c qlsi : qlm.qliChilds){
                        qlsi.QuoteLineItemId__c = qlm.qliParent.Id;
                        qlsisToUpsert.add(qlsi);
                    }       
                    for(QLIDescription__c qliDesc : qlm.qliDescriptions){
                        // System.debug('qlm.qliDescriptions ' + qliDesc);
                        QLIDescription__c qliDescUpsrt = new QLIDescription__c(QuoteLineItemId__c = qlm.qliParent.Id, TitleCZ__c = qliDesc.TitleCZ__c, TitleEN__c = qliDesc.TitleEN__c, 
                                                                            DescriptionCZ__c = qliDesc.DescriptionCZ__c, DescriptionEN__c = qliDesc.DescriptionEN__c, 
                                                                            RowNumber__c = qliDesc.RowNumber__c, Id = qliDesc.Id, Name = qliDesc.Name);
                        // System.debug('qliDescUpsrt ' + qliDescUpsrt);
                        qliDescsToUpsert.add(qliDescUpsrt);
                    }
                }
            }
            upsert qliDescsToUpsert;
            upsert qlsisToUpsert;

            /* Set Shipment Price to 0 if FreeShipping option is enabled */
            if(qliTransportFree) {
                updateTransportQliPrice(qliTransToUpsert);
            }

            if(qliTransToUpsert.RowTotalPrice__c != 0){
                qliTransToUpsert.LineCost__c = qliTransToUpsert.TC_AccommodationCost__c + qliTransToUpsert.TC_AssemblyCost__c + qliTransToUpsert.TC_MaterialShippingCost__c + qliTransToUpsert.TC_ShippingCost__c;
                switch on currQuote.CurrencyIsoCode{
                    when 'EUR'{
                        CurrencyType ctEur = [SELECT ConversionRate,IsActive,IsoCode FROM CurrencyType WHERE IsoCode = 'EUR' AND IsActive = true];
                        qliTransToUpsert.LineCost__c = qliTransToUpsert.LineCost__c / ctEur.ConversionRate;
                    }
                    when 'USD'{
                        CurrencyType ctUsd = [SELECT ConversionRate,IsActive,IsoCode FROM CurrencyType WHERE IsoCode = 'USD' AND IsActive = true];
                        qliTransToUpsert.LineCost__c = qliTransToUpsert.LineCost__c / ctUsd.ConversionRate;
                    }
                }
                
                upsert qliTransToUpsert;
            }else if(qliTransToUpsert.RowTotalPrice__c == 0 && qliTransToUpsert.Id != null && !qliTransportFree){
                delete qliTransToUpsert;
            }
    
            // DELETE
            for(Mdl.QuoteLineMdl qlm : qlmsToDel){
                qlisToDelete.add(qlm.qliParent);
                setQliIdToDel.add(qlm.qliParent.Id);
            }
            qlsisToDelete = [SELECT Id FROM QuoteLineSubItem__c WHERE QuoteLineItemId__c IN: setQliIdToDel];
            qliDescsToDelete = [SELECT Id FROM QLIDescription__c WHERE QuoteLineItemId__c IN: setQliIdToDel];
            
            delete qliDescsToDelete;
            delete qlsisToDelete;
            delete qlisToDelete;
            sm.isSuccess = true;
        }catch(Exception e){
            sm.isSuccess = false;
            sm.message = e.getMessage();
        }
        return sm;
    }

    private static void updateTransportQliPrice(QuoteLineItem qliTransToUpsert) {
        qliTransToUpsert.RowTotalPrice__c = 0;
        qliTransToUpsert.UnitPrice__c = 0;
        qliTransToUpsert.UnitPrice = 0;
        // qliTransToUpsert.TC_MaterialShippingCost__c =0.0;
        // qliTransToUpsert.TC_ShippingCost__c = 0; 
        // qliTransToUpsert.LineCost__c = 0;
        // qliTransToUpsert.TC_AccommodationCost__c = 0.0; 
        // qliTransToUpsert.TC_AssemblyCost__c = 0.0;

        upsert qliTransToUpsert;
    }

    public static Mdl.QuoteLineMdl[] auraGetLineCost(Mdl.QuoteLineMdl[] qlms){
        for(Mdl.QuoteLineMdl qlm : qlms){
            System.debug('Product Unit Cost ' + qlm.qliParent.PricebookEntry.Product2.UnitCost__c);
            System.debug('CurrencyIsoCode ' + qlm.qliParent.Quote.CurrencyIsoCode);
            if(qlm.qliParent.PricebookEntry.Product2.UnitCost__c == null){
                qlm.qliParent.PricebookEntry.Product2.UnitCost__c = 0;
            }
                qlm.qliParent.LineCost__c = qlm.qliParent.PricebookEntry.Product2.UnitCost__c * qlm.qliParent.Quantity;
            
            system.debug('LINECOST__ ' + qlm.qliParent.LineCost__c);
            
        }
        return qlms;
    }

    @AuraEnabled
    public static Mdl.ProductMdl auraGetProductMdl(String prodId, String currencyIsoCode){
        Mdl.ProductMdl prodmdl = new Mdl.ProductMdl();
        prodmdl.pbeProduct = auraGetProductByPBE(prodId, currencyIsoCode);
        prodmdl.prodDescs = [SELECT Id, ProductId__c, TitleCZ__c, TitleEN__c, DescriptionCZ__c, DescriptionEN__c, RowNumber__c, Name FROM ProductDescription__c WHERE ProductId__c =: prodId];
        prodmdl.materials =[SELECT BundleItemId__c, Quantity__c, Type__c, BundleId__c, IsEditable__c, IsVisible__c, IsTemplateProduct__c, IsVisibleOnPDF__c, Position__c,
                BundleItemId__r.Name, BundleItemId__r.QuantityUnitOfMeasure, BundleItemId__r.Description, BundleItemId__r.Specification__c, BundleItemId__r.ProductDescriptionCZ__c,
                BundleItemId__r.ProductDescriptionEN__c, BundleItemId__r.BusinessName__c, BundleItemId__r.BusinessNameEN__c, BundleId__r.BusinessName__c, BundleItemId__r.UnitCost__c
                FROM BOM__c WHERE BundleId__c =: prodId];
        return prodmdl;
        
    }

    @AuraEnabled
    public static PricebookEntry auraGetProductByPBE(String prodId, String currencyIsoCode){
        return [SELECT Id, CurrencyIsoCode, Product2Id, Product2.Type__c, Product2.UnitCost__c, Product2.Description, Product2.QuantityUnitOfMeasure, Product2.Specification__c,
                        Product2.RequestForTechnicianId__c, Product2.UnitPriceCZK__c, Product2.UnitPriceEUR__c, Product2.UnitPriceUSD__c, Product2.CurrencyIsoCode, Product2.IsTemplateProduct__c,
                        Product2.Name, Product2.ProductDescriptionCZ__c, Product2.ProductDescriptionEN__c, Product2.IsDefault__c, Product2.BusinessName__c, Product2.BusinessNameEN__c
                        FROM PricebookEntry WHERE CurrencyIsoCode =: currencyIsoCode AND Product2Id =: prodId LIMIT 1];
    }

    @AuraEnabled
    public static Decimal auraGetCZKReward(Decimal totalPrice, String curr){
        System.debug('FEE ' + totalPrice);
        Decimal czkTotalPrice = Hlp.getDatedCZKValue(totalPrice, curr, Date.today());
        System.debug('CZK Reward ' + czkTotalPrice);
        return czkTotalPrice;
    }
    
    public class QuoteManagerMdl {
        @AuraEnabled public Boolean isQuotedPrinted         {get;set;}
        @AuraEnabled public Quote qt                        {get;set;}
        @AuraEnabled public Mdl.QuoteLineMdl[] qlis         {get;set;}
        @AuraEnabled public PricebookEntry[] products       {get;set;}  
        @AuraEnabled public Mdl.PickVal[] specPicklist      {get;set;}
        @AuraEnabled public Mdl.PickVal[] prodFamilies      {get;set;}
        @AuraEnabled public QuoteLineItem   qliTransport    {get;set;}
        @AuraEnabled public Decimal accountDiscount         {get;set;}
        @AuraEnabled public Boolean quoteIsLocked           {get;set;}
        @AuraEnabled public Boolean needAppprove            {get;set;}
        @AuraEnabled public ProjectSalesFee__c[] psfs       {get;set;}
        public QuoteManagerMdl(){
            qlis = new Mdl.QuoteLineMdl[]{};
            specPicklist = new Mdl.PickVal[]{};
            prodFamilies = new Mdl.PickVal[]{};
            psfs = new ProjectSalesFee__c[]{};
        }
    }

    
}