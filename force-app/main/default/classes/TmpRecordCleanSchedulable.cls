global class TmpRecordCleanSchedulable implements Schedulable {
	public static Id temporaryRecordId = [SELECT Id FROM TemporaryRecord__c WHERE Name =:Cst.RFT_TMP_RECORD_NAME LIMIT 1].Id;
	public static String JOB_NAME = 'Temporary Record Clean';

	global static void start(){
		String cronExpr = Cst.CRON_EXPRESSION;
		if(Test.isRunningTest()){
			JOB_NAME += ' TEST';
		}
		String jobID = System.schedule(JOB_NAME, cronExpr, new TmpRecordCleanSchedulable());
	}

	global void execute(SchedulableContext sc){
		Datetime currentdate = System.now();
		Datetime weekBefore = currentdate.addDays(-7);
		ContentDocumentLink[] cdls = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink 
										WHERE LinkedEntityId =: temporaryRecordId];
		Set<String> cdIds = new Set<String>();										
		for(ContentDocumentLink cdl : cdls){
			cdIds.add(cdl.ContentDocumentId);
		}
		ContentVersion[] cvs = [SELECT Id, ContentDocumentId FROM ContentVersion 
								WHERE ContentDocumentId IN: cdIds AND CreatedDate <=: weekBefore AND IsLatest = true];
		ContentDocument[] cds = new ContentDocument[]{};
		for(ContentVersion cv : cvs){
			cds.add(new ContentDocument(Id = cv.ContentDocumentId));
		}				
		delete cds;
	}

	global static void cancel(){
		if(Test.isRunningTest()){
			JOB_NAME += ' TEST';
		}
		CronTrigger[] cts = [SELECT Id, CronExpression, CronJobDetailId, CronJobDetail.Name, State FROM CronTrigger WHERE CronJobDetail.Name LIKE: JOB_NAME];
		for(CronTrigger ct : cts){
        	System.abortJob(ct.Id);			
		}
	}
}