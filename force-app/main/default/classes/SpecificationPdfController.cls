public class SpecificationPdfController  {

	private final Quote quote;
	public QuoteLineItem[] 			qlis			{get;set;}
	public String 					currentDate 	{get;set;}
	public ContentDocumentLink[]	prodImg			{get;set;}
	public ContentDocumentLink[]	prodLay			{get;set;}
	//public BOM__c[]					boms			{get;set;}
	public Mdl.SpecificationMdl[]	sms 			{get;set;}
	public QuoteLineItem[] 			qlisOpt 		{get;set;}

	// Number formating settings
    private final Integer precision = 2;
	private final String separator = ' ';
	private final String decimalSeparator = ',';

	public SpecificationPdfController(ApexPages.StandardController stdc){
		prodImg = new ContentDocumentLink[]{};
		prodLay = new ContentDocumentLink[]{};
		sms = new Mdl.SpecificationMdl[]{};
		qlisOpt = new QuoteLineItem[]{};
		Id[] prodIds = new Id[]{};

		String[] fieldsToAdd = new String[]{'Id', 'QuoteNumber', 'Name', 'Language__c',
											'Opportunity.Name', 'Opportunity.OpportunityNo__c'};

		if(!Test.isRunningTest()){
			stdc.addFields(fieldsToAdd);
		}

		this.quote = (Quote)stdc.getRecord();

		QuoteLineItem[] qlis = [SELECT Discount, Subtotal, RowDiscount__c, TotalPrice, ProductDescriptionCZ__c, ProductDescriptionEN__c, UnitPrice, Quantity, ProductFamily__c, 
								ProductName__c, CurrencyIsoCode, Description, Product2Id, Product2.BusinessName__c, Product2.BusinessNameEN__c, RelatedOptionalEquipment__c, Product2.Type__c, Product2.Name,
								(SELECT Id, Name, ProductName__c, Description__c, ProductDescriptionCZ__c, ProductDescriptionEN__c, Quantity__c, Product2Id__r.BusinessName__c, Product2Id__r.BusinessNameEN__c, 
								Product2Id__r.Name, Product2Id__r.Specification__c, Product2Id__r.Type__c
									FROM QuoteLineSubItems__r WHERE IsVisible__c = true AND IsVisibleOnPDF__c = true ORDER BY SortNumber__c)
								FROM QuoteLineItem WHERE QuoteId =: quote.Id AND IsTransport__c = false ORDER BY RowNumber__c ASC];
		

		for(QuoteLineItem qli : qlis){
			prodIds.add(qli.Product2Id);
			System.debug('QLI ' + qli.RelatedOptionalEquipment__c);
			if(!String.isBlank(qli.RelatedOptionalEquipment__c)){
				qlisOpt.add(qli);
			}
		}
		System.debug('QLIOpt ' + qlisOpt);
		
		/*BOM__c[] boms = [SELECT Type__c, BundleItemId__r.Name, BundleId__c, Quantity__c FROM BOM__c WHERE BundleId__c IN: prodIds AND IsVisible__c = true ORDER BY SortNumber__c];
		System.debug('BOMS ' + boms);*/


		for(QuoteLineItem qli : qlis){
			if(qli.Product2.Type__c == Cst.PROD_TYPE_PRODUCT){
				Mdl.SpecificationMdl sm = new Mdl.SpecificationMdl();
				sm.qli = qli;
				for(QuoteLineSubItem__c qlsi: qli.QuoteLineSubItems__r){
					sm.qlsis.add(qlsi);
				}
				for(QuoteLineItem optQli : qlis){
					if(optQli.RelatedOptionalEquipment__c == qli.Id){
						sm.optQlis.add(optQli);
					}
				}
				sms.add(sm);
			}
		}	
		Datetime currDateTime = datetime.now();
		currentDate = currDateTime.format('dd.MM.YYYY');

		if(prodIds.size() > 0){
			
			for(ContentDocumentLink cdl: [SELECT ContentDocument.LatestPublishedVersionId, LinkedEntityId, ContentDocument.Title FROM ContentDocumentLink WHERE LinkedEntityId IN: prodIds]){
				if(cdl.ContentDocument.Title == 'Specification'){
					this.prodImg.add(cdl);
				}else if(cdl.ContentDocument.Title == 'SpecificationDetail' && quote.Language__c == 'cs'){
					this.prodLay.add(cdl);
				}else if(cdl.ContentDocument.Title == 'SpecificationDetailEN' && quote.Language__c == 'en_US'){
					this.prodLay.add(cdl);
				}
			}
		}
	}
}