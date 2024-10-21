global class GoogleCalendarSyncSchedulable implements Schedulable {
    public final static String JOB_NAME_BASE = 'Sprinx Google Cal Sync Job';
	public static String cron = '0 0 * * * ?';

	// Schedule Job
	public static void scheduleJob() {
		String jobName = JOB_NAME_BASE;
		if(Test.isRunningTest()){
			jobName += ' TEST';
		}
		System.debug('Scheduling ' + jobName);
		System.schedule(jobName, cron, new GoogleCalendarSyncSchedulable());
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
		GoogleCalendarService.getUpdatedGoogleCalEvents();
	}
}