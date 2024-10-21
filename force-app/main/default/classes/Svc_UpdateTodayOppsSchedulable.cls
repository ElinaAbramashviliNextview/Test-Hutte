public class Svc_UpdateTodayOppsSchedulable implements Schedulable{
    // THIS SCHEDULABLE NEEDS TO RUN AFTER CURRENCIES ARE SYNCED
    // WILL EXPORT TODAY OPPS TO WHICH EXCHANGE RATES MIGHT HAVE CHANGED TO CSV AGAIN
	public final static String JOB_NAME_BASE = 'Sprinx CNB Update Today Opps Job';
	public static String cron = '0 40 23 * * ?';

	// Schedule Job
	public static void scheduleJob() {
		String jobName = JOB_NAME_BASE;
		if(Test.isRunningTest()){
			jobName += ' TEST';
		}
		System.debug('Scheduling ' + JOB_NAME_BASE);
		System.schedule(jobName, cron, new Svc_UpdateTodayOppsSchedulable());
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

	public static void worker() {
        Opportunity[] opps = [SELECT Id FROM Opportunity WHERE CloseDate =: System.today() AND CurrencyIsoCode != 'CZK'];
        update opps;
	}
}