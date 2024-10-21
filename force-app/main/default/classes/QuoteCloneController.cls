public without sharing class QuoteCloneController {
    
    
    @AuraEnabled
    public static String auraGetOppCurrency(String oppId){
        return [SELECT CurrencyIsoCode FROM Opportunity WHERE Id =: oppId LIMIT 1].CurrencyIsoCode;
    }

    @AuraEnabled
    public static String auraClone(String quoteId, String oppId){
        // Savepoint sp = Database.setSavepoint();
        // try {
            Opportunity opp = [SELECT Account.DiscountAccount__c, Street__c, City__c, PostalCode__c, Country__c, State__c, CurrencyIsoCode, Account.BillingStreet, Account.BillingCity, Account.BillingCountry, Account.BillingPostalCode, Account.BillingState FROM Opportunity WHERE Id =: oppId LIMIT 1];
            Decimal newAccDiscount = (opp.Account.DiscountAccount__c != null && opp.Account.DiscountAccount__c > 0) ? opp.Account.DiscountAccount__c + 0 : 0;
            Quote originalQuote = [SELECT Id, Phone, Description__c, Description, Discount, Email, GrandTotal, Language__c, QuoteDiscount__c, 
                                    QuoteDiscountValue__c, QuoteToAddress, QuoteTotalDiscount__c, Subtotal__c, TotalPrice__c, ProjectSalesFee__c, ProjectSalesFeeValue__c, ContactId,
                                    QPdf_IsDisplayQuoteTotalPrice__c, QPdf_IsDisplayQuoteSubtotalPrice__c, QPdf_IsDisplayQuoteDiscount__c, QPdf_IsDisplayProductSubtotal__c, QPdf_IsDisplayListPrice__c,
                                    QPdf_IsDisplayDiscountUnitPrice__c, QPdf_IsDisplayDiscount__c
                                    FROM Quote WHERE Id =: quoteId LIMIT 1];
            QuoteLineItem[] qlis = [SELECT Id, PricebookEntryId, TC_AccommodationCost__c, TC_AssemblyCost__c, ServiceDate, IsDefault__c, Discount, LineCost__c, Description, ListPrice, TC_MaterialShippingCost__c,
                                    ParentId__c, Product2Id, ProductDescriptionEN__c, ProductDescriptionCZ__c, ProductFamily__c, ProductName__c, Quantity, QuantityUnitOfMeasure__c, RowDiscount__c, CreatedDate,
                                    RowNumber__c, RowTotalDiscount__c, UnitPrice, TC_ShippingCost__c, Subtotal, RowTotalPrice__c, TotalPrice, IsTransport__c, UnitPrice__c, RelatedOptionalEquipment__c, IsShowInQuotePDF__c
                                    FROM QuoteLineItem WHERE QuoteId =: quoteId];

            // Get All QLI Ids
            // If any QLI has greater discount
            Set<Id> qliIds = new Set<Id>();
            Boolean greaterDiscount = false;
            Decimal tmpSubtotal = 0;
            for(QuoteLineItem qli : qlis){
                qliIds.add(qli.Id);
                if(!qli.IsTransport__c){
                    System.debug('Testing ' + qli.RowDiscount__c + ', ' + newAccDiscount);
                    tmpSubtotal += (qli.ListPrice * qli.Quantity) * (1 - (((qli.RowDiscount__c > newAccDiscount) ? newAccDiscount : qli.RowDiscount__c) / 100));
                }
                if(qli.RowTotalDiscount__c > newAccDiscount){
                    greaterDiscount = true;
                }
            }

            // Get All Quote Line Sub Items associated with qlis
            QuoteLineSubItem__c[] qlsis = [SELECT Id, Description__c, IsEditable__c, OwnerId, Position__c, Product2Id__c, ProductBusinessName__c, ProductDescriptionCZ__c, ProductDescriptionEN__c, ProductName__c,
                                    Quantity__c, QuantityUnitOfMeasure__c, Name, SortNumber__c, IsTemplateProduct__c, IsVisible__c, IsVisibleOnPDF__c, QuoteLineItemId__c 
                                    FROM QuoteLineSubItem__c WHERE QuoteLineItemId__c IN: qliIds];
            
            Map<Id, QuoteLineSubItem__c[]> qlsiByQLIId = new Map<Id, QuoteLineSubItem__c[]>();
            for(QuoteLineSubItem__c qlsi : qlsis){
                QuoteLineSubItem__c[] tmp = qlsiByQLIId.get(qlsi.QuoteLineItemId__c);
                if(tmp == null){
                    tmp = new QuoteLineSubItem__c[]{};
                    qlsiByQLIId.put(qlsi.QuoteLineItemId__c, tmp);
                }
                tmp.add(qlsi);
            }
            
            // Get All Quote Line Descriptions associated with qlis
            QLIDescription__c[] qliDescs = [SELECT DescriptionCZ__c, DescriptionEN__c, Name, OwnerId, RowNumber__c, TitleCZ__c, TitleEN__c, QuoteLineItemId__c 
                                            FROM QLIDescription__c WHERE QuoteLineItemId__c IN: qliIds];
            
            Map<Id, QLIDescription__c[]> qlidByQLIId = new Map<Id, QLIDescription__c[]>();
            for(QLIDescription__c qlid : qliDescs){
                QLIDescription__c[] tmp = qlidByQLIId.get(qlid.QuoteLineItemId__c);
                if(tmp == null){
                    tmp = new QLIDescription__c[]{};
                    qlidByQLIId.put(qlid.QuoteLineItemId__c, tmp);
                }
                tmp.add(qlid);
            }
                                    
            System.debug('QLIS ' + qlis);

            // Clone Quote
            Quote clonedQuote = originalQuote.clone(false, true, false, false);
            if(greaterDiscount){
                clonedQuote.QuoteDiscount__c = 0;
                clonedQuote.QuoteDiscountValue__c = 0;
                clonedQuote.Subtotal__c = tmpSubtotal;
            }

            clonedQuote.IsCloned__c = true;
            clonedQuote.Status = 'Processed';
            clonedQuote.OpportunityId = oppId;
            clonedQuote.ParentId__c = quoteId;
            clonedQuote.IsSendAddressToOpportunity__c = false;

            clonedQuote.ShippingStreet = opp.Street__c;
            clonedQuote.ShippingCity = opp.City__c;
            clonedQuote.ShippingPostalCode = opp.PostalCode__c;
            clonedQuote.ShippingCountry = opp.Country__c;

            clonedQuote.BillingCity = opp.Account.BillingCity;
            clonedQuote.BillingCountry = opp.Account.BillingCountry;
            clonedQuote.BillingPostalCode = opp.Account.BillingPostalCode;
            clonedQuote.BillingState = opp.Account.BillingState;
            clonedQuote.BillingStreet = opp.Account.BillingStreet;
            insert clonedQuote;

            // Clone RFT & RFTLink
            RequestForTechnicianLink__c[] rftLinks = new RequestForTechnicianLink__c[]{};
            RequestForTechnician__c[] quoteRFTs = [SELECT Id, QuoteId__c FROM RequestForTechnician__c WHERE QuoteId__c =: originalQuote.Id];
            if(quoteRFTs.size() > 0){
                for(RequestForTechnician__c rft : quoteRFTs){
                    rftLinks.add(new RequestForTechnicianLink__c(QuoteId__c = clonedQuote.Id, RequestForTechnicianId__c = rft.Id));
                }
            }
            
            RequestForTechnicianLink__c[] quoteRFTLinks = [SELECT Id, QuoteId__c, RequestForTechnicianId__c FROM RequestForTechnicianLink__c WHERE QuoteId__c =: originalQuote.Id];
            if(quoteRFTLinks.size() > 0){
                for(RequestForTechnicianLink__c originalRFTLink : quoteRFTLinks){
                    RequestForTechnicianLink__c clonedRFTLink = originalRFTLink.clone(false, true, false, false);
                    clonedRFTLink.QuoteId__c = clonedQuote.Id;
                    rftLinks.add(clonedRFTLink);
                }
            }

            if(rftLinks.size() > 0){
                insert rftLinks;
            }
            
            // Clone QLI
            Decimal qtTotalPrice = 0;
            Decimal qtTotalListPrice = 0;
            Decimal qtTotalPriceWithTrans = 0;
            Decimal totalLineCost = 0;
            QuoteLineItem[] clonedQLIs = new QuoteLineItem[]{};
            for(QuoteLineItem originalQLI : qlis){
                totalLineCost += originalQLI.LineCost__c;
                QuoteLineItem clonedQLI = originalQLI.clone(false, true, false, false);
                if(originalQLI.CreatedDate < Cst.VISIBLE_IN_PDF_DATE){
                    clonedQLI.IsShowInQuotePDF__c = true;
                }
                if(clonedQLI.RowTotalDiscount__c > newAccDiscount && !clonedQLI.IsTransport__c){
                    System.debug('NewAcc Discount ' + newAccDiscount);
                    clonedQLI.RowTotalDiscount__c = newAccDiscount;
                    clonedQLI.UnitPrice = clonedQLI.ListPrice * (1 - (clonedQLI.RowTotalDiscount__c / 100));
                }
                if(clonedQLI.RowDiscount__c > newAccDiscount && !clonedQLI.IsTransport__c){
                    clonedQLI.RowDiscount__c = newAccDiscount;
                    clonedQLI.UnitPrice__c = clonedQLI.ListPrice * (1 - (clonedQLI.RowDiscount__c / 100));
                    clonedQLI.RowTotalPrice__c = (clonedQLI.ListPrice * clonedQLI.Quantity) * (1 - (clonedQLI.RowDiscount__c / 100));
                }

                clonedQLI.OriginId__c = originalQLI.Id;
                clonedQLI.QuoteId = clonedQuote.Id;
                clonedQLIs.add(clonedQLI);

                // Prepare values for QT
                if(!clonedQLI.IsTransport__c){
                    qtTotalPrice += clonedQLI.RowTotalPrice__c;
                    qtTotalListPrice += (clonedQLI.ListPrice * clonedQLI.Quantity);
                }
                qtTotalPriceWithTrans += clonedQLI.RowTotalPrice__c;
            }

            
            insert clonedQLIs;

            // Add Lookup RelatedOptionalEquipment
            for(QuoteLineItem clonedQLIOrigin : clonedQLIs){
                for(QuoteLineItem clonedQLI : clonedQLIs){
                    if(!String.isBlank(clonedQLI.RelatedOptionalEquipment__c) && clonedQLI.RelatedOptionalEquipment__c == clonedQLIOrigin.OriginId__c){
                        clonedQLI.RelatedOptionalEquipment__c = clonedQLIOrigin.Id;
                    }
                }
            }
            update clonedQLIs;
            
            clonedQuote.TotalPrice__c = qtTotalPriceWithTrans;
            clonedQuote.QuoteTotalDiscount__c = (qtTotalListPrice == 0) ? 0 :(1 - (qtTotalPrice / qtTotalListPrice)) * 100;
            for(ProjectSalesFee__c psf: [SELECT Id, LowerRange__c, HigherRange__c, Reward__c FROM ProjectSalesFee__c]){
                Decimal quoteTotalDisc = clonedQuote.QuoteTotalDiscount__c.setScale(2);
                if(psf.LowerRange__c >= quoteTotalDisc && psf.HigherRange__c <= quoteTotalDisc){
                    Decimal czkTotalPrice = Hlp.getDatedCZKValue(clonedQuote.TotalPrice__c, opp.CurrencyIsoCode, Date.today());
                    clonedQuote.ProjectSalesFee__c = psf.Reward__c;
                    clonedQuote.ProjectSalesFeeValue__c = (czkTotalPrice - totalLineCost) * (psf.Reward__c / 100);
                    break;
                }
            }
            update clonedQuote;

            // Clone QLSI
            if(clonedQLIs.size() > 0){
                QuoteLineSubItem__c[] clonedQLSIs = new QuoteLineSubItem__c[]{};
                QLIDescription__c[] clonedQLIDs = new QLIDescription__c[]{};
                for(QuoteLineItem clonedQLI : clonedQLIs){
                    if(qlsiByQLIId.get(clonedQLI.OriginId__c) != null){
                        System.debug('qlsiByQLIId '+ qlsiByQLIId.get(clonedQLI.OriginId__c));
                        for(QuoteLineSubItem__c originalQLSI : qlsiByQLIId.get(clonedQLI.OriginId__c)){
                            QuoteLineSubItem__c clonedQLSI = originalQLSI.clone(false, true, false, false);
                            clonedQLSI.QuoteLineItemId__c = clonedQLI.Id;
                            clonedQLSIs.add(clonedQLSI);
                        }
                    }
                    if(qlidByQLIId.get(clonedQLI.OriginId__c) != null){
                        System.debug('qlsiByQLIId '+ qlidByQLIId.keySet());
                        for(QLIDescription__c originalQLID : qlidByQLIId.get(clonedQLI.OriginId__c)){
                            QLIDescription__c clonedQLID = originalQLID.clone(false, true, false, false);
                            clonedQLID.QuoteLineItemId__c = clonedQLI.Id;
                            clonedQLIDs.add(clonedQLID);
                        }
                    }
                }
                insert clonedQLSIs;
                insert clonedQLIDs;
            }
            

            return clonedQuote.Id;
        // } catch (Exception e) {
        //     Database.rollback(sp);
        //     throw new AuraHandledException(e.getMessage());
        // }
    }
}