public with sharing class InvoicePaymentCalculationSchedulable implements Schedulable {
    public final static String JOB_NAME_BASE = 'Sprinx Invoice Payment Calculation Schedulable Job';
	public static String cron = '0 0 * * * ?';

	// Schedule Job
	public static void scheduleJob() {
		String jobName = JOB_NAME_BASE;
		if(Test.isRunningTest()){
			jobName += ' TEST';
		}
		System.debug('Scheduling ' + jobName);
		System.schedule(jobName, cron, new InvoicePaymentCalculationSchedulable());
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
        Datetime hourBack = Datetime.now().addMinutes(-120);
        Payment__c[] ps = [SELECT Id,InvoiceId__c FROM Payment__c WHERE CreatedDate >=: hourBack AND InvoiceId__c != null];
        Set<Id> invIdsSet = new Set<Id>();
        for(Payment__c p : ps){
            invIdsSet.add(p.InvoiceId__c);
        }
        Id[] invIds = new Id[]{};
        invIds.addAll(invIdsSet);
		Database.executeBatch(new InvoicePaymentCalculationBatch(invIds), 1);
	}
}