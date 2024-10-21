public with sharing class TechnicianPricebookEntrySchedulable implements Schedulable{
    public final static String JOB_NAME_BASE = 'Technician Pricebook Entry Schedulable';
	public static String cron = '0 30 * ? * *';

	// Schedule Job
	public static void scheduleJob() {
		String jobName = JOB_NAME_BASE;
		if(Test.isRunningTest()){
			jobName += ' TEST';
		}
		System.debug('Scheduling ' + jobName);
		System.schedule(jobName, cron, new TechnicianPricebookEntrySchedulable());
	}

	// Execute
	public void execute(SchedulableContext sc) {
		worker();
	}

	// Global Cancel
	public static void cancel() {
		String jobName = JOB_NAME_BASE;
		if(Test.isRunningTest()){
			jobName += ' TEST';
		}
		CronTrigger[] cts = [SELECT Id, CronExpression, CronJobDetailId, CronJobDetail.Name, State FROM CronTrigger WHERE CronJobDetail.Name = :jobName];
		for (CronTrigger c : cts) {
			System.abortJob(c.ID);
			System.debug('Cron Job ' + c.CronJobDetail.Name + ' (' + c.ID + ') aborted.');
		}
	}


    public static void worker(){
        TechnicianPricebookEntrySettings__c tpbes = TechnicianPricebookEntrySettings__c.getValues('default');
        tpbes.SessionId__c = UserInfo.getSessionId();
        update tpbes;
    }
}