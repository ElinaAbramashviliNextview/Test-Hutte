public class Svc_OppCSVExport  {

    @Future(callout=true)
    public static void exportOppsToGdrive(){
        GoogleDriveAuth__c sett = GoogleDriveAuth__c.getValues('default');
        if(sett == null){
            System.debug('Google Drive Settings undefined. Job cannot run.');
            return;
        }

        if(sett.OppDisableSync__c){
            System.debug('Google Drive Sync disabled.');
            return;
        }

        /*Opportunity[] opps = [SELECT Id, Name, CurrencyIsoCode, AccountNameText__c, Owner.Name, CreatedDate, StageName, OpportunityNo__c, CloseDate, Street__c, City__c, PostalCode__c,
            Country__c, ProformaPercent__c, ProformaValue__c, IsClosed, IsWon, Probability, RealizationStartDate__c, RealizationEndDate__c, RealizationEndPlan__c, Amount, PaymentTerm__c,
            OrderDueDate__c, ProformaIssuedDatePlan__c, ProformaPaidDatePlan__c, OrderDeliveryDatePlan__c, HandoverDate__c, FinalInvoicePaymentTerm__c,
            SyncedQuoteId, SyncedQuote.ShippingStreet, SyncedQuote.ShippingCity, SyncedQuote.ShippingPostalCode, SyncedQuote.ShippingCountry, SyncedQuote.GrossMargin__c, SyncedQuote.GrossMarginPercent__c,
            SyncedQuote.TotalCost__c, SyncedQuote.TotalPrice__c, SyncedQuote.TechnicianId__c, SyncedQuote.TechnicianId__r.Name, SyncedQuote.TechnicianUserId__c, SyncedQuote.TechnicianUserId__r.Name, SyncedQuote.PrintedDate__c, SyncedQuote.SentDate__c,
            ResponsibleTechnicianId__c, ResponsibleTechnicianId__r.Name, ProjectManagerId__c, ProjectManagerId__r.Name,
            (SELECT Id, Product2.Name, Quantity FROM OpportunityLineItems)
            FROM Opportunity 
            ORDER BY LastModifiedDate DESC NULLS LAST
            LIMIT 50];*/

        String q = 'SELECT Id, Name, CurrencyIsoCode, AccountNameText__c, Owner.Name, CreatedDate, StageName, OpportunityNo__c, CloseDate, Street__c, City__c, PostalCode__c,' +
            'Country__c, ProformaPercent__c, ProformaValue__c, IsClosed, IsWon, Probability, RealizationStartDate__c, RealizationEndDate__c, RealizationEndPlan__c, Amount, PaymentTerm__c,' +
            'OrderDueDate__c, ProformaIssuedDatePlan__c, ProformaPaidDatePlan__c, OrderDeliveryDatePlan__c, HandoverDate__c, FinalInvoicePaymentTerm__c,' +
            'SyncedQuoteId, SyncedQuote.ShippingStreet, SyncedQuote.ShippingCity, SyncedQuote.ShippingPostalCode, SyncedQuote.ShippingCountry, SyncedQuote.GrossMargin__c, SyncedQuote.GrossMarginPercent__c,' +
            'SyncedQuote.TotalCost__c, SyncedQuote.TotalPrice__c, SyncedQuote.TechnicianId__c, SyncedQuote.TechnicianId__r.Name, SyncedQuote.TechnicianUserId__c, SyncedQuote.TechnicianUserId__r.Name, SyncedQuote.PrintedDate__c, SyncedQuote.SentDate__c,'+
            'ResponsibleTechnicianId__c, ResponsibleTechnicianId__r.Name, ProjectManagerId__c, ProjectManagerId__r.Name,' +
            '(SELECT Id, Product2.Name, Quantity FROM OpportunityLineItems)';
            
            if(sett.OppSyncLastRun__c == null){
                q += ' FROM Opportunity';
            }else{
                q += ' FROM Opportunity WHERE LastModifiedDate >=' + getQueryDTformat(sett.OppSyncLastRun__c);
            }

            System.debug(q);
        // get opportunities
        Opportunity[] opps = Database.query(q);
        if(opps.isEmpty()){
            return;
        }
        Set<Id> oppIds = new Set<Id>{};
        Set<Id> syncedQuoteIds = new Set<Id>{};
        for(Opportunity opp : opps){
            oppIds.add(opp.Id);
            if(opp.SyncedQuoteId != null){
                syncedQuoteIds.add(opp.SyncedQuoteId);
            }
        }

        // get related invocies
        Invoice__c[] invs = [SELECT Id, IsProforma__c, OpportunityId__c, DueDate__c, TotalWithVAT__c, CurrencyIsoCode, IssuedDate__c, IsPaid__c, PaidDate__c FROM Invoice__c WHERE OpportunityId__c IN: oppIds];
        Map<Id,Invoice__c[]> invoicesByOppId = new Map<Id,Invoice__c[]>();
        for(Invoice__c inv : invs){
            Invoice__c[] tmp = invoicesByOppId.get(inv.OpportunityId__c);
            if(tmp == null){
                tmp = new Invoice__c[]{};
                invoicesByOppId.put(inv.OpportunityId__c, tmp);
            }
            tmp.add(inv);
        }

        // get related orders
        Order__c[] ords = [SELECT Id, DeliveryDate__c, DueDate__c, OpportunityId__c FROM Order__c WHERE OpportunityId__c IN: oppIds];
        Map<Id,Order__c[]> ordersByOppId = new Map<Id,Order__c[]>();
        for(Order__c ord : ords){
            Order__c[] tmp = ordersByOppId.get(ord.OpportunityId__c);
            if(tmp == null){
                tmp = new Order__c[]{};
                ordersByOppId.put(ord.OpportunityId__c, tmp);
            }
            tmp.add(ord);
        }

        // get quoteline items
        QuoteLineItem[] syncedQlis = [SELECT Id, TC_AccommodationCost__c, TC_AssemblyCost__c, TC_MaterialShippingCost__c, TC_ShippingCost__c, QuoteId, Product2Id, IsTransport__c, LineCost__c, CurrencyIsoCode, Quantity,
            (SELECT Id, Product2Id__c, Quantity__c FROM QuoteLineSubItems__r) 
            FROM QuoteLineItem 
            WHERE QuoteId IN: syncedQuoteIds];
        Map<Id, QuoteLineItem[]> quoteLineItemsbyQuoteId = new Map<Id, QuoteLineItem[]>();
        Map<Id, QuoteLineItem[]> transportQlisByQuoteId = new Map<Id, QuoteLineItem[]>();
        Set<Id> usedProductsIDs = new Set<Id>();
        for(QuoteLineItem qli : syncedQlis){
            // create separate map for transport qlis
            if(qli.IsTransport__c){
                QuoteLineItem[] tmp = transportQlisByQuoteId.get(qli.QuoteId);
                if(tmp == null){
                    tmp = new QuoteLineItem[]{};
                    transportQlisByQuoteId.put(qli.QuoteId, tmp);
                }
                tmp.add(qli);
            }
            // map of all qlis by quote id for costs calculation
            QuoteLineItem[] tmp = quoteLineItemsbyQuoteId.get(qli.QuoteId);
            if(tmp == null){
                tmp = new QuoteLineItem[]{};
                quoteLineItemsbyQuoteId.put(qli.QuoteId, tmp);
            }
            tmp.add(qli);
            //add product id for product query
            if(qli.Product2Id != null){
                usedProductsIDs.add(qli.Product2Id);
            }

            // skip to next record if subitems null
            if (qli.QuoteLineSubItems__r == null){
                continue;
            }
            // iterate over qli subitems to add its product ids
            for(QuoteLineSubItem__c qlsi : qli.QuoteLineSubItems__r){
                if(qlsi.Product2Id__c != null){
                    usedProductsIDs.add(qlsi.Product2Id__c);
                }
            }
        }

        Map<Id,Product2> productByIdMap = new Map<Id,Product2>([SELECT Id, Name, Specification__c, UnitCost__c, CurrencyIsoCode FROM Product2 WHERE Id =: usedProductsIDs]);

        

        String csvHeader = '"Název projektu",';
        csvHeader += '"Číslo projektu",';
        csvHeader += '"Zákazník",';
        csvHeader += '"Místo realizace",';
        csvHeader += '"Obchodník",';
        csvHeader += '"Datum příjetí poptávky",';
        csvHeader += '"Termín zpracování CN",';
        csvHeader += '"Datum odeslání CN",';
        csvHeader += '"Stav",';
        csvHeader += '"Datum získáno",';
        csvHeader += '"Pravděpod. prodeje (%(",';
        csvHeader += '"Výše zálohy (%)",';
        csvHeader += '"Výše zálohy (hodnota)",';
        csvHeader += '"Datum splatnosti Záloha",';
        csvHeader += '"Záloha - platební podmínky",';
        csvHeader += '"Záloha uhrazena",';
        csvHeader += '"Výše KF",';
        csvHeader += '"Datum splatnosti KF",';
        csvHeader += '"KF uhrazena",';
        csvHeader += '"Datum nástup na realizaci",';
        csvHeader += '"Datum realizace ukončení",';
        csvHeader += '"Plánované ukončení realizace",';
        csvHeader += '"Zpracuje VD",';
        csvHeader += '"Systém",';
        csvHeader += '"Nákladová cena",';
        csvHeader += '"Prodejní cena",';
        csvHeader += '"P1 (hodnota)",';
        csvHeader += '"P2 (%)",';
        csvHeader += '"Doprava (náklad)",';
        csvHeader += '"Přesun hmot (náklad)",';
        csvHeader += '"Náklad montáž (náklad)",';
        csvHeader += '"Ubytování (náklad)",';
        csvHeader += '"d_predano_real",';
        csvHeader += '"d_vystavena_kf_real",';
        csvHeader += '"D_vystavena_zf_plan",';
        csvHeader += '"D_vystavena_zf_real",';
        csvHeader += '"D-zaplacena_zf_plan",';
        csvHeader += '"D-zaplacena_zf_real",';
        csvHeader += '"d_zaplacena_kf_real",';
        csvHeader += '"D-predano_plan",';
        csvHeader += '"projektovy_manazer",';
        csvHeader += '"Vyrobna (naklad)",';
        csvHeader += '"Calounictvi (naklad)",';
        csvHeader += '"zpracuje CN",';
        csvHeader += '"Final Invoice Payment Term",';
        csvHeader += '"Mena",';
        csvHeader += '"Prodejni cena - cizi mena"\n';

        String csvBody = '';
        
        for(Opportunity opp : opps){
            csvBody += getOppCSVLine(opp, invoicesByOppId.get(opp.Id), ordersByOppId.get(opp.Id), transportQlisByQuoteId.get(opp.SyncedQuoteId), quoteLineItemsbyQuoteId.get(opp.SyncedQuoteId), productByIdMap);
        }

        //System.debug(csvBody);

        
        /* FOR TEST PURPOSES */
        /*Account a = new Account(Id = '0011X00000RFTZcQAP', Description=csvHeader+csvBody);
        update a;*/

        /* FOR TEST CREATE CSV ATTACHMENT ON ACCOUNT */
        /*String fullCsv = csvHeader+csvBody;
        fullCsv = EncodingUtil.urlDecode(fullCsv, 'UTF-8');
        fullCsv = EncodingUtil.urlEncode(fullCsv, 'Windows-1250');

        Attachment attch = new Attachment(Body = Blob.valueOf(fullCsv), Name = 'SLProjSforce'+ System.now().format('yy-MM-dd_HH-mm')+'.csv', ParentId = '0011X00000RFTZcQAP');
        insert attch;*/

        /* Send Data to GDRIVE */
        String filename = 'SLProjSforce'+ System.now().format('yy-MM-dd_HH-mm')+'.csv';
        Mdl.BaseResponse res = GoogleDriveService.uploadFileGDrive(filename, 'text/csv', sett.OppSyncFolderEId__c, EncodingUtil.base64Encode(Blob.valueOf(csvHeader+csvBody)));
        if (res.isSuccess){
            // log full export
            if(sett.OppSyncLastRun__c == null){
                SyncUtils.logServiceActivity('Svc_OppCSVExport', 'success', 200, 'Gdrive Sync Successfull', '' , '','GDrive response: ' + res.msg + ' \n\n CSV: \n\n Fullexport too large. CSV not exported');
            }else{
                SyncUtils.logServiceActivity('Svc_OppCSVExport', 'success', 200, 'Gdrive Sync Successfull', '' ,'', 'GDrive response: ' + res.msg + ' \n\n CSV: \n\n' + csvHeader+csvBody);
            }
            sett.OppSyncLastRun__c = System.now();
            update sett;

        }else{
            //TODO : create service log
            System.debug(res.msg);
            SyncUtils.logServiceActivity('Svc_OppCSVExport', 'error', 500, res.msg);
        }
        
    }


    public static string getOppCSVLine(Opportunity opp, Invoice__c[] invs, Order__c[] ords, QuoteLineItem[] transportQlis, QuoteLineItem[] quoteLines, Map<Id,Product2> productByIdMap){
        System.debug('Opp: ' + opp.id + ' prop: ' + opp.Probability);
        // Addres
        String addr = null;
        String valueSeparator = '","';
        String lineEnd =  '" \n';
        Boolean hasSyncedQuote = (opp.SyncedQuoteId != null);
        if (hasSyncedQuote){
            addr = Hlp.createAddressTxt(opp.SyncedQuote.ShippingStreet, opp.SyncedQuote.ShippingCity, opp.SyncedQuote.ShippingPostalCode, opp.SyncedQuote.ShippingCountry);
        }else{
            addr = Hlp.createAddressTxt(opp.Street__c, opp.City__c, opp.PostalCode__c, opp.Country__c);
        }
        
        // Prepare product names with count, separated by comma
        String prodsJoin = '';
        String[] prods = new String[]{};
        for(OpportunityLineItem oli : opp.OpportunityLineItems){
            prods.add(oli.Product2.Name + ' ('+ Integer.valueOf(oli.Quantity) +')');
        }
        prodsJoin = String.join(prods, ',');

        // prepare proforma invoice, last invoice & lastInvoiceDate
        Invoice__c proformaInv = null;
        Invoice__c lastInv = null;
        Date lastInvoiceDate = null;
        if(invs != null){
            for(Invoice__c inv : invs){
                if(inv.IsProforma__c){
                    proformaInv = inv;
                }

                if(lastInvoiceDate == null || lastInvoiceDate < inv.IssuedDate__c){
                    lastInvoiceDate = inv.IssuedDate__c;
                }

                if(!inv.IsProforma__c && (lastInv == null || lastInv.IssuedDate__c < inv.IssuedDate__c)){
                    lastInv = inv;
                }
            }       
        }

        // preapre order
        Order__c ord = null;
        if(ords != null && !ords.isEmpty()){
            ord = ords[0];
        }

        // prepare tranport quoteline item
        QuoteLineItem transportQli = null;
        if(transportQlis != null && !transportQlis.isEmpty()){
            transportQli = transportQlis[0];
        }

        // prepare calounictvi and vyroba costs
        Decimal calounictvi_cost = 0;
        Decimal vyroba_cost = 0;

        if(quoteLines != null){
            for(QuoteLineItem qli : quoteLines){
                // check quoteline items
                Product2 tmp = productByIdMap.get(qli.Product2Id);
                // split Specification multiselect values to list
                String[] specsSplit = null;
                if (tmp != null && tmp.Specification__c != null){
                    specsSplit = tmp.Specification__c.split(';');
                }
                //add to cost if list contains specifications
                if(specsSplit != null && specsSplit.contains(Cst.PROD_SPEC_CALOUNENI)){
                    calounictvi_cost += qli.LineCost__c;
                }
                if(specsSplit != null && specsSplit.contains(Cst.PROD_SPEC_VYROBA)){
                    vyroba_cost += qli.LineCost__c;
                }

                // check quoteline subitems
                if (qli.QuoteLineSubItems__r != null){
                    for(QuoteLineSubItem__c qlsi : qli.QuoteLineSubItems__r){
                        Product2 tmpProd = productByIdMap.get(qlsi.Product2Id__c);
                        // split Specification multiselect values to list
                        String[] specsSplit2 = null;
                        if (tmpProd != null && tmpProd.Specification__c != null){
                            specsSplit2 = tmpProd.Specification__c.split(';');
                        }
                        if(specsSplit2 != null && specsSplit2.contains(Cst.PROD_SPEC_CALOUNENI)){
                            calounictvi_cost += qli.Quantity * qlsi.Quantity__c * getConvertedCZKValue(tmpProd.UnitCost__c, tmpProd.CurrencyIsoCode, opp.CloseDate);
                        }
                        if(specsSplit2 != null && specsSplit2.contains(Cst.PROD_SPEC_VYROBA)){
                            vyroba_cost += qli.Quantity * qlsi.Quantity__c * getConvertedCZKValue(tmpProd.UnitCost__c, tmpProd.CurrencyIsoCode, opp.CloseDate);
                        }
                    }
                }

            }       
        }


        //prepare CSV line for opp
        String line = '"';
        line += opp.Name.replace('"', '""') + valueSeparator;  // opp name
        line += opp.OpportunityNo__c + valueSeparator; // opp number
        line += ((opp.AccountNameText__c != null) ? opp.AccountNameText__c.replace('"', '""') : null )+ valueSeparator; // account name
        line += addr + valueSeparator; // address txt
        line += opp.Owner.Name.replace('"', '""') + valueSeparator; // opp owner
        line += opp.CreatedDate.format('YYYY-MM-dd') + valueSeparator; // opp created date
        line += ((hasSyncedQuote) ? getFormatedDate(opp.SyncedQuote.PrintedDate__c) : null) + valueSeparator; // quote printed date
        line += ((hasSyncedQuote) ? getFormatedDate(opp.SyncedQuote.SentDate__c) : null) + valueSeparator; // qute sent date
        line += opp.StageName + valueSeparator; // opp stage
        line += ((opp.IsClosed && opp.IsWon) ? getFormatedDate(opp.CloseDate) : null) + valueSeparator; // closed won date
        line += opp.Probability +  valueSeparator; // probability
        line += opp.ProformaPercent__c +  valueSeparator; // proforma percent
        line += getConvertedCZKValue(opp.ProformaValue__c, opp.CurrencyIsoCode, opp.CloseDate) +  valueSeparator; // proforma value
        line += ((proformaInv != null) ? getFormatedDate(proformaInv.DueDate__c) : null) + valueSeparator; // proforma due date
        line += opp.PaymentTerm__c+ valueSeparator; // payment terms
        line += ((proformaInv != null) ? proformaInv.IsPaid__c : null) + valueSeparator; // proforma paid
        line += ((opp.Amount != null) ? getConvertedCZKValue(opp.Amount, opp.CurrencyIsoCode, opp.CloseDate) : 0) - ((opp.ProformaValue__c != null) ? getConvertedCZKValue(opp.ProformaValue__c, opp.CurrencyIsoCode, opp.CloseDate) : 0) + valueSeparator; // total - proforma
        line += ((lastInv != null) ? getFormatedDate(lastInv.DueDate__c) : null) + valueSeparator; // KF due date
        line += ((lastInv != null) ? lastInv.IsPaid__c : null) + valueSeparator; // KF paid
        line += getFormatedDate(opp.RealizationStartDate__c) +  valueSeparator; // opp start reallizace
        line += getFormatedDate(opp.RealizationEndDate__c) +  valueSeparator; // opp konec realizace
        line += getFormatedDate(opp.RealizationEndPlan__c) +  valueSeparator; // opp plan dokonceni realizace
        line += ((opp.ResponsibleTechnicianId__c != null) ? opp.ResponsibleTechnicianId__r.Name.replace('"', '""') : null )+  valueSeparator; // opp technic
        line += prodsJoin + valueSeparator; // seznam produktů
        line += ((hasSyncedQuote) ? opp.SyncedQuote.TotalCost__c.setScale(2) : null) + valueSeparator; // nákladova cena
        line += ((opp.Amount != null) ? getConvertedCZKValue(opp.Amount, opp.CurrencyIsoCode, opp.CloseDate) : 0) + valueSeparator; // prodejní cena
        // TOTAL FROM SYNCED QUOTE
        //line += ((hasSyncedQuote) ? getConvertedCZKValue(opp.SyncedQuote.TotalPrice__c, opp.CurrencyIsoCode) : null) + valueSeparator; // prodejní cena
        line += ((hasSyncedQuote) ? opp.SyncedQuote.GrossMargin__c : null) + valueSeparator; // P1 (hodnota)
        line += ((hasSyncedQuote) ? opp.SyncedQuote.GrossMarginPercent__c : null) + valueSeparator; // P2 (%)
        line += ((transportQli != null) ? getConvertedCZKValue(transportQli.TC_ShippingCost__c, opp.CurrencyIsoCode, opp.CloseDate) : null) + valueSeparator; // doprava naklad
        line += ((transportQli != null) ? getConvertedCZKValue(transportQli.TC_MaterialShippingCost__c, opp.CurrencyIsoCode, opp.CloseDate) : null) + valueSeparator; // presun hmot naklad
        line += ((transportQli != null) ? getConvertedCZKValue(transportQli.TC_AssemblyCost__c, opp.CurrencyIsoCode, opp.CloseDate) : null) + valueSeparator; // naklad montaz 
        line += ((transportQli != null) ? getConvertedCZKValue(transportQli.TC_AccommodationCost__c, opp.CurrencyIsoCode, opp.CloseDate) : null) + valueSeparator; // ubytovani naklad
        line += getFormatedDate(opp.HandoverDate__c) + valueSeparator; // d_preadno_real
        line += ((lastInv != null) ? lastInv.IssuedDate__c : null)+ valueSeparator; //d_vystavena_kf_real
        line += getFormatedDate(opp.ProformaIssuedDatePlan__c) +  valueSeparator; // D_vystavena_zf_plan
        line += ((proformaInv != null) ? getFormatedDate(proformaInv.IssuedDate__c) : null) + valueSeparator; // D_vystavena_zf_real
        line += getFormatedDate(opp.ProformaPaidDatePlan__c) +  valueSeparator; // D-zaplacena_zf_plan
        line += ((proformaInv != null) ? getFormatedDate(proformaInv.PaidDate__c) : null) + valueSeparator; // D-zaplacena_zf_real
        line += ((lastInv != null) ? getFormatedDate(lastInv.PaidDate__c) : null) + valueSeparator; // D_zaplacena_kf_real
        line += getFormatedDate(opp.RealizationEndDate__c) +  valueSeparator; // D-predano_plan
        line += ((opp.ProjectManagerId__c != null) ? opp.ProjectManagerId__r.Name.replace('"', '""') : null )+  valueSeparator; // projektovy manager
        line += String.valueOf(vyroba_cost)+  valueSeparator; // vyroba naklad
        line += String.valueOf(calounictvi_cost)+  valueSeparator; // calounictvi naklad
        line += ((hasSyncedQuote && opp.SyncedQuote.TechnicianUserId__c != null) ? opp.SyncedQuote.TechnicianUserId__r.Name.replace('"', '""') : null) + valueSeparator; // zpracuje CN
        line += String.valueOf(opp.FinalInvoicePaymentTerm__c) + valueSeparator; // Final Invoice Payment Term
        line += String.valueOf(opp.CurrencyIsoCode) + valueSeparator; // mena
        line += ((opp.CurrencyIsoCode == 'CZK') ? '0' : String.valueOf(opp.Amount)) + lineEnd; // prodejni cena - cizi mena



        return line;
    }

    public static string getFormatedDate(Date d){
        if(d == null){
            return null;
        }else{
            return d.year() + '-' + String.valueOf(d.month()).leftPad(2,'0') + '-' + String.valueOf(d.day()).leftPad(2,'0'); 
        }
    }

    public static string getQueryDTformat(Datetime d){
        if (d == null){
            return null;
        }else{
            return d.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        }
    }


    public static Decimal getConvertedCZKValue(Decimal value, String CurrencyCode, Date dt){
        CNBRatesSyncSettings__c sett = CNBRatesSyncSettings__c.getValues('default');
        if(sett == null || !sett.isAdvancedCurrRateSync__c){
            return getCZKValue(value, CurrencyCode);
        }else{
            return getDatedCZKValue(value, currencyCode, dt);
        }
    }

    
    public static Map<String,Double> m_currencyByCodeMap {get;set;}
    public static Decimal getCZKValue(Decimal value, String CurrencyCode){
        // prepare currency by code map
        if(m_currencyByCodeMap == null){
            m_currencyByCodeMap = new Map<String,Double>{};
            CurrencyType[] cts = [SELECT ConversionRate, IsoCode FROM CurrencyType WHERE IsActive = True AND IsCorporate = false];
            for(CurrencyType ct : cts){
                m_currencyByCodeMap.put(ct.IsoCode, ct.ConversionRate);
            }
        }

        if(value == null){
            return null;
        }

        // currency is CZK, no need to convert
        if(CurrencyCode == 'CZK'){
            return value.setScale(2);
        }
        // currency conversion rate not defined in SF, return null;
        if(m_currencyByCodeMap.get(CurrencyCode) == null){
            return null;
        }

        Decimal czkValue = value * (1/m_currencyByCodeMap.get(CurrencyCode));
        return czkValue.setScale(2);
    }
    
    public static Map<String,DatedConversionRate[]> m_datedCurrencyListByCodeMap {get;set;}
    public static Decimal getDatedCZKValue(Decimal value, String currencyCode, Date dt){
        // value or date not defined, return null
        if(value == null || dt == null){
            return null;
        }

        // currency is CZK, no need to convert, return scaled value
        if(currencyCode == 'CZK'){
            return value.setScale(2);
        }

        // check if map exists, if not, populate values
        // prepare currency by code map
        if(m_datedCurrencyListByCodeMap == null){
            m_datedCurrencyListByCodeMap = new Map<String, DatedConversionRate[]>{};
            DatedConversionRate[] dcrs = [SELECT ConversionRate, IsoCode, StartDate, NextStartDate FROM DatedConversionRate ORDER BY StartDate DESC];
            for(DatedConversionRate dcr :dcrs){
                DatedConversionRate[] convRatesList = m_datedCurrencyListByCodeMap.get(dcr.IsoCode);
                if(convRatesList == null){
                    convRatesList = new DatedConversionRate[]{};
                    m_datedCurrencyListByCodeMap.put(dcr.IsoCode, convRatesList);
                }
                convRatesList.add(dcr);
            }
        }

        DatedConversionRate[] datedCurrencyList = m_datedCurrencyListByCodeMap.get(currencyCode);
        Double convRate = null;
        // not found, something went wrong, return null
        if(datedCurrencyList == null){
            return null;
        }else{  //if found, iterate ower map to 
            for(DatedConversionRate dcr: datedCurrencyList){
                if(dt >= dcr.StartDate && dt < dcr.NextStartDate){
                    convRate = dcr.ConversionRate;
                    break;
                }
            }
        }

        if(convRate != null){
            Decimal czkValue = value * (1/convRate);
            return czkValue.setScale(2);
        }else{
            return null;
        }
    }
}