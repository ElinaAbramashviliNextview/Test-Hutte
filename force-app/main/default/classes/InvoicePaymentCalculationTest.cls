@IsTest
public with sharing class InvoicePaymentCalculationTest {
	@IsTest
	public static void InvoicePaymentCalculationTest() {
		Invoice__c inv = new Invoice__c(TotalWithVAT__c = 1000, CurrencyIsoCode = 'CZK');
		insert inv;

		Payment__c p = new Payment__c(Amount__c = 1000, CurrencyIsoCode = 'CZK', InvoiceId__c = inv.Id);
		insert p;
		InvoicePaymentCalculationSchedulable.scheduleJob();
		InvoicePaymentCalculationSchedulable.cancel();

		Test.startTest();
		InvoicePaymentCalculationSchedulable.worker();
		Test.stopTest();
	}
}