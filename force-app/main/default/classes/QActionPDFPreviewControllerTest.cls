@isTest 
private class QActionPDFPreviewControllerTest {

	@isTest
	private static void auraSavePDFTest() {
		SyncServiceSettings__c stt = new SyncServiceSettings__c();
		stt.Name = 'AccountToSAP';
		stt.DisableSync__c = true;
		insert stt;

		Opportunity opp = new Opportunity(StageName='Qualification', Name='Opp Test', CloseDate=Date.newInstance(2019, 8, 24));	
		insert opp;
		Quote qt = new Quote(Name='Quote Test', OpportunityId=opp.Id);
		insert qt;

		QActionPDFPreviewController.auraSavePDF(qt.Id, 'QuotePDF');
	}
}