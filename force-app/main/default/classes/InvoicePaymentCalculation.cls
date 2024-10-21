public with sharing class InvoicePaymentCalculation {
	@InvocableMethod
	public static void InvoicePaymentCalculation(Id[] invIds) {
		System.debug(invIds);
		Database.executeBatch(new InvoicePaymentCalculationBatch(invIds), 1);
		
		/*Invoice__c[] invToRecalc = [SELECT Id, IsPaid__c, PaidDate__c, CurrencyIsoCode, TotalWithVAT__c, (SELECT Id, Amount__c, CurrencyIsoCode FROM Payments__r)
								FROM Invoice__c 
								WHERE Id IN: invIds];

		Invoice__c[] invToUpdate = new Invoice__c[]{};
		for(Invoice__c inv : invToRecalc){
			// calc sum of related payments (only in same currency as invoice)
			Decimal paymentsSum = 0;
			for(Payment__c p : inv.Payments__r){
				if(inv.CurrencyIsoCode == p.CurrencyIsoCode){
					paymentsSum += p.Amount__c;
				}
			}

			// check if should be marked as paid
			if(paymentsSum == inv.TotalWithVAT__c){
				inv.IsPaid__c = true;
				inv.PaidDate__c = System.today();
				invToUpdate.add(inv);
			}
		}

		if(!invToUpdate.isEmpty()){
			update invToUpdate;
		}*/
	}
}