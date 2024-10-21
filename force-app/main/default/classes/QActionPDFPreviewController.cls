public class QActionPDFPreviewController  {

	@AuraEnabled
	public static Boolean auraCheckCD(Id quoteId, String typePdf){
		Quote qt = [SELECT Name, Status FROM Quote WHERE Id =: quoteId];
		ContentDocumentLink[] cdls = new ContentDocumentLink[]{};
		if(typePdf=='QuotePDF'){
			cdls = [SELECT ContentDocumentId, ContentDocument.Title FROM ContentDocumentLink WHERE ContentDocument.Title =: qt.Name AND LinkedEntityId =: qt.Id];
		}else{
			cdls = [SELECT ContentDocumentId, ContentDocument.Title FROM ContentDocumentLink WHERE ContentDocument.Title =: qt.Name+'_Specification' AND LinkedEntityId =: qt.Id];
		}
		if(cdls.size() > 0){
			return false;
		}else{
			return true;
		}
	}
	
	@AuraEnabled
	public static void auraSavePDF(Id quoteId, String typePdf){
		Quote qt = [SELECT Id, OpportunityId, Name, Status FROM Quote WHERE Id =: quoteId];
		Boolean isQuotePdf = (typePdf=='QuotePDF')? true : false;

		PageReference pr = (isQuotePdf)? Page.QuotePdf: Page.SpecificationPdf;
		pr.getParameters().put('id', quoteId);
		Blob pdfBody;

		if(Test.isRunningTest()){
			pdfBody = Blob.valueOf('Unit.Test');
		}else{
			pdfBody = pr.getContent();
		}

		ContentVersion cv = new ContentVersion();
		if(isQuotePdf){
			cv.Title=qt.Name;
			cv.PathOnClient=qt.Name+'.pdf';
		}else{
			cv.Title=qt.Name+'_Specif';
			cv.PathOnClient=qt.Name+'_Specif.pdf';
		}
		cv.VersionData = pdfBody;
		cv.Origin='H';
		insert cv;
		ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId =: cv.Id];
		ContentDocumentLink cdl = new ContentDocumentLink(ContentDocumentId = cd.Id, LinkedEntityId = quoteId, Visibility = 'AllUsers', ShareType = 'V');
		insert cdl;

		if(isQuotePdf){
			qt.Status = Cst.QUOTE_STATUS_PRINTED;
			update qt;
		}
		// save pdf to related opp gdrive folder
		GoogleDriveService.savePDFtoGDrive(isQuotePdf, cv.Id, qt.Id);
		// if quote is first - sync it to opportunity
		if(qt.Name.endsWith('.1')){
			Hlp.syncQuoteToOpportunity(qt.Id, qt.OpportunityId);
		}
	}

	@AuraEnabled
	public static Boolean auraCheckTmplProd(Id quoteId, String typePdf){
		Boolean hasTmplProd = false;
		if(typePdf=='QuotePDF'){
			QuoteLineItem[] qlis = [SELECT Id, (SELECT Id, IsTemplateProduct__c FROM QuoteLineSubItems__r) FROM QuoteLineItem WHERE QuoteId =: quoteId];
			for(QuoteLineItem qli: qlis){
				for(QuoteLineSubItem__c qlsi : qli.QuoteLineSubItems__r){
					if(qlsi.IsTemplateProduct__c){
						hasTmplProd = true;
					}					
				}
			}
		}
		return hasTmplProd;
	} 
}