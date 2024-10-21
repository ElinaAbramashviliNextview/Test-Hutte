public with sharing class QuotePdfController {

    private final Quote quote;
    public User currentUser { get; set; }
    public QuoteLineItem[] qlis { get; set; }
    public Mdl.QuoteLineItemMdl[] qlisProd { get; set; }
    public Mdl.QuoteLineItemMdl[] qlisTrans { get; set; }
    public String currentDate { get; set; }
    public Decimal totalPriceVal { get; set; }
    public Integer prodCount { get; set; }
    public String subTotalProd { get; set; }
    public String subTotalTrans { get; set; }
    public String quoteDiscount { get; set; }
    public String prodTotaWithAllDisc { get; set; }
    public String totalPrice { get; set; }
    public ContentDocumentLink[] cdls { get; set; }
    public String quoteCurrency { get; set; }
    public Boolean isDraft { get; set; }
    public Integer colspan { get; set; }

    // Number formating settings
    private final static Integer precision = 2;
    private final static String separator = ' ';
    private final static String decimalSeparator = ',';

    public QuotePdfController(ApexPages.StandardController stdc) {
        Id[] prodIds = new Id[]{
        };
        qlisProd = new Mdl.QuoteLineItemMdl[]{
        };
        qlisTrans = new Mdl.QuoteLineItemMdl[]{
        };
        Decimal subTotalProdVal = 0;
        Decimal subTotalTransVal = 0;
        Decimal prodTotaWithAllDiscVal = 0;
        totalPriceVal = 0;
        prodCount = 0;
        colspan = 4;

        String[] fieldsToAdd = new String[]{
                'Id', 'QuoteNumber', 'QuoteNo__c', 'Name', 'Language__c', 'QPdf_IsDisplayDiscount__c', 'QPdf_IsDisplayDiscountUnitPrice__c', 'QPdf_IsDisplayListPrice__c',
                'QPdf_IsDisplayQuoteTotalPrice__c', 'QPdf_IsDisplayQuoteDiscount__c', 'ShippingStreet', 'ShippingCity', 'QuoteDiscount__c', 'NeedApprove__c', 'IsApproved__c',
                'QPdf_IsDisplayQuoteSubtotalPrice__c', 'QPdf_IsDisplayProductSubtotal__c',
                'Account.Name',
                'Opportunity.Name',
                'Owner.Name',
                'TechnicianId__r.Name',
                'TechnicianUserId__r.Name',
                'Contact.Name', 'Contact.Email', 'Contact.MobilePhone'
        };

        if (!Test.isRunningTest()) {
            stdc.addFields(fieldsToAdd);
        }
        this.quote = (Quote) stdc.getRecord();

        if (!quote.QPdf_IsDisplayDiscount__c) {
            colspan--;
        }
        if (!quote.QPdf_IsDisplayDiscountUnitPrice__c) {
            colspan--;
        }
        if (!quote.QPdf_IsDisplayListPrice__c) {
            colspan--;
        }

        if (quote.NeedApprove__c && !quote.IsApproved__c) {
            isDraft = true;
        } else {
            isDraft = false;
        }
        System.debug('isDraft ' + isDraft);
        this.quoteCurrency = this.quote.CurrencyIsoCode;
        this.currentUser = [SELECT Name, Email, MobilePhone, CompanyName FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        System.debug('Current User ' + currentUser);
        this.qlis = [
                SELECT Discount, Subtotal, RowDiscount__c, RowTotalPrice__c, TotalPrice, ProductDescriptionCZ__c, ProductDescriptionEN__c, ListPrice, Quantity, ProductFamily__c, RowNumber__c, RelatedOptionalEquipment__c,
                        ProductName__c, CurrencyIsoCode, Description, Product2Id, Product2.BusinessName__c, Product2.BusinessNameEN__c, Product2.Name, Product2.Specification__c, UnitPrice__c, IsTransport__c, Product2.Type__c, IsShowInQuotePDF__c, CreatedDate, (SELECT Id, QuoteLineItemId__c, TitleCZ__c, TitleEN__c, DescriptionCZ__c, DescriptionEN__c, RowNumber__c FROM QLIDescriptions__r ORDER BY RowNumber__c), (
                        SELECT Id, Name, ProductName__c, Description__c, ProductDescriptionCZ__c, ProductDescriptionEN__c, Product2Id__r.BusinessName__c, Product2Id__r.BusinessNameEN__c, Product2Id__r.Name, Product2Id__r.Specification__c
                        FROM QuoteLineSubItems__r
                        WHERE IsVisible__c = TRUE AND IsVisibleOnPDF__c = TRUE
                        ORDER BY SortNumber__c
                )
                FROM QuoteLineItem
                WHERE QuoteId = :quote.Id
                ORDER BY RowNumber__c ASC
        ];

        Decimal tmpSubtotal = 0;
        Integer counter = 0;
        Boolean addLast = true;
        for (Integer i = 0; i < this.qlis.size(); i++) {
            if (qlis[i].IsTransport__c) {
                Mdl.QuoteLineItemMdl qlim = fillModel(qlis[i]);
                qlisTrans.add(qlim);
                subTotalTransVal += qlis[i].RowTotalPrice__c;
            } else {
                Mdl.QuoteLineItemMdl qlim = fillModel(qlis[i]);
                if (qlis[i].RelatedOptionalEquipment__c == null) {
                    if (tmpSubtotal == 0) {
                        counter++;
                        tmpSubtotal += qlis[i].RowTotalPrice__c;
                    } else {
                        Mdl.QuoteLineItemMdl qlimDelimiter = createDelimiter(tmpSubtotal, counter);
                        qlisProd.add(qlimDelimiter);
                        tmpSubtotal = qlis[i].RowTotalPrice__c;
                        counter = 1;
                    }
                } else {
                    counter++;
                    tmpSubtotal += qlis[i].RowTotalPrice__c;

                    // Add subtotal to last product
                    if (i == qlis.size() - 1) {
                        System.debug('LAST QLI ' + qlis[i].Product2.BusinessName__c);
                        Mdl.QuoteLineItemMdl qlimDelimiter = createDelimiter(tmpSubtotal, counter);
                        qlisProd.add(qlim);
                        qlisProd.add(qlimDelimiter);
                        addLast = false;
                    }
                }
                if (addLast) {
                    qlisProd.add(qlim);
                }
                subTotalProdVal += qlis[i].UnitPrice__c * qlis[i].Quantity;
                prodTotaWithAllDiscVal += qlis[i].RowTotalPrice__c;
                prodIds.add(qlis[i].Product2Id);
                prodCount++;
            }
        }
        totalPriceVal = subTotalTransVal + prodTotaWithAllDiscVal;
        subTotalProd = formatCurrency(subTotalProdVal, 0, true);
        quoteDiscount = formatPercent(quote.QuoteDiscount__c, 2, true);
        subTotalTrans = formatCurrency(subTotalTransVal, 0, true);
        totalPrice = formatCurrency(totalPriceVal, 0, true);
        prodTotaWithAllDisc = formatCurrency(prodTotaWithAllDiscVal, 0, true);
        Datetime currDateTime = Datetime.now();
        currentDate = currDateTime.format('dd.MM.YYYY');
        if (!Test.isRunningTest()) {
            if (prodIds.size() > 0) {
                this.cdls = [SELECT ContentDocument.LatestPublishedVersionId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :prodIds AND ContentDocument.Title = 'ProductImage'];
            }
        }
    }


    //===================================================================================================
    // HELPERS - HELPERS - HELPERS - HELPERS - HELPERS - HELPERS - HELPERS - HELPERS - HELPERS - HELPERS 
    //===================================================================================================   

    public Mdl.QuoteLineItemMdl createDelimiter(Decimal subtotal, Integer counter) {
        Mdl.QuoteLineItemMdl qlimDelimiter = new Mdl.QuoteLineItemMdl();
        qlimDelimiter.isDelimiter = true;
        qlimDelimiter.subtotal = formatCurrency(subtotal, 0, true);
        qlimDelimiter.showDelimiter = counter > 1;
        return qlimDelimiter;
    }

    public Mdl.QuoteLineItemMdl fillModel(QuoteLineItem qli) {


        Mdl.QuoteLineItemMdl qlim = new Mdl.QuoteLineItemMdl();
        qlim.Id = qli.Id;
        qlim.Product2Id = qli.Product2Id;
        if (quote.Language__c == 'cs') {
            qlim.ProductBusName = qli.Product2.BusinessName__c;
        } else if (quote.Language__c == 'en_US') {
            qlim.ProductBusName = qli.Product2.BusinessNameEN__c;
        }
        qlim.ProductType = qli.Product2.Type__c;
        qlim.ProductName = qli.Product2.Name;
        qlim.ProductFamily = qli.ProductFamily__c;
        qlim.ProductSpecification = qli.Product2.Specification__c;
        qlim.ProductDescriptionCZ = qli.ProductDescriptionCZ__c;
        qlim.ProductDescriptionEN = qli.ProductDescriptionEN__c;
        qlim.Description = qli.Description;
        qlim.Quantity = formatNumber(qli.Quantity, 0);
        qlim.ListPrice = formatCurrency(qli.ListPrice, 0, true);
        if (qli.IsTransport__c) {
            qlim.RowTotalPrice = formatCurrency((qli.UnitPrice__c * qli.Quantity), 0, true);
        } else {
            qlim.RowTotalPrice = formatCurrency(((qli.ListPrice * qli.Quantity) * (1 - qli.RowDiscount__c / 100)), 0, true);
        }

        qlim.RowDiscount = formatPercent(qli.RowDiscount__c, 2, true);
        qlim.DiscountUnitPrice = formatCurrency(qli.UnitPrice__c, 0, true);
        qlim.RelatedOptional = qli.RelatedOptionalEquipment__c;
        qlim.qliDescs = qli.QLIDescriptions__r;
        qlim.qlsis = qli.QuoteLineSubItems__r;

        // IsShowInQuotePDF__c default value was set to true but default value on old records was false
        qlim.showProduct = (qli.CreatedDate > Cst.VISIBLE_IN_PDF_DATE && qli.IsShowInQuotePDF__c == false) ? false : true;
        return qlim;
    }

    public String formatNumber(Decimal val, Integer scale) {
        return format(val, scale, false, false, false);
    }
    public String formatNumber(Double val, Integer scale) {
        return format((Decimal) val, scale, false, false, false);
    }
    public String formatPercent(Decimal val, Integer scale, Boolean addPercentSymbol) {
        return format(val, scale, false, false, addPercentSymbol);
    }
    public String formatCurrency(Decimal val, Integer scale, Boolean addCode) {
        return format(val, scale, true, addCode, false);
    }
    public String formatCurrency(Double val, Integer scale, Boolean addCode) {
        return format((Decimal) val, scale, true, addCode, false);
    }
    private String format(Decimal val, Integer scale, Boolean isCurrency, Boolean addCurrencyCode, Boolean addPercentSymbol) {
        if (val == null) val = 0;

        String result = '';
        String sVal = String.valueOf(val.setScale(scale)); // get absolute value
        Integer len = sVal.length();
        if (scale > 0) scale += 1; // reflect decimal separator
        Decimal absVal = Math.abs(val);
        if (absVal > 999999999) {
            result += sVal.substring(0, len - 9 - scale) + separator + sVal.substring(len - 9 - scale, len - 6 - scale) + separator + sVal.substring(len - 6 - scale, len - 3 - scale) + separator + sVal.substring(len - 3 - scale, len);
        } else if (absVal > 999999) {
            result += sVal.substring(0, len - 6 - scale) + separator + sVal.substring(len - 6 - scale, len - 3 - scale) + separator + sVal.substring(len - 3 - scale, len);
        } else if (absVal > 999) {
            result += sVal.substring(0, len - 3 - scale) + separator + sVal.substring(len - 3 - scale, len);
        } else {
            result += sVal;
        }

        String currencyName = '';
        switch on quoteCurrency {
            when 'CZK' {
                currencyName = 'Kč';
            }
            when 'USD' {
                currencyName = '$';
            }
            when 'EUR' {
                currencyName = '€';
            }
        }

        if (addCurrencyCode) {
            result += ' ' + currencyName;
        } else if (addPercentSymbol) {
            result += ' %';
        }

        result = result.replace('.', decimalSeparator);
        return result;
    }

    public String getProductListPriceSummary(QuoteLineItem qli, Decimal discountedPrice) {
        // All discounted if discount applied
        return formatCurrency(discountedPrice * qli.Quantity, precision, true) + ((qli.Quantity > 1) ? ' (' + formatNumber(qli.Quantity, 2) + 'x ' + formatCurrency(discountedPrice, precision, true) + ')' : '');
    }
}