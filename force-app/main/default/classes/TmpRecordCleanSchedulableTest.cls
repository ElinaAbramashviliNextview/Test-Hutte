@isTest 
private class TmpRecordCleanSchedulableTest {

	@isTest private static void CO_TmpRecordCleanSchedulableTest(){
		TemporaryRecord__c tr = new TemporaryRecord__c(Name='SystemRFT');
		insert tr;
		TmpRecordCleanSchedulable.start();
		TmpRecordCleanSchedulable.cancel();
	}
}