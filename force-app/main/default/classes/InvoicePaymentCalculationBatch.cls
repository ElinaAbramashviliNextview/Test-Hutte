public with sharing class InvoicePaymentCalculationBatch implements Database.Batchable<SObject>{

	private Id[] invIds = new Id[]{};

	public InvoicePaymentCalculationBatch(Id[] recIds) {
		this.invIds = recIds;
	}
	
	public Database.QueryLocator start(Database.BatchableContext bc) {
		String q = 'SELECT Id, IsPaid__c, PaidDate__c, CurrencyIsoCode, TotalWithVAT__c, (SELECT Id, Amount__c, CurrencyIsoCode, CreatedDate FROM Payments__r) FROM Invoice__c WHERE Id IN: invIds AND IsPaid__c = false';
		return Database.getQueryLocator(q);
	}
	
	public void execute(Database.BatchableContext bc, List<Invoice__c> scope){
		// process each batch of records
		if(scope == null || scope.size() != 1){
			System.debug('Scope size must be 1!');
		}else{
			Invoice__c inv = scope[0];
			Boolean doUpdate = false;
			// calc sum of related payments (only in same currency as invoice)
			Decimal paymentsSum = 0;
			Datetime lastPaymentDate = null;
			for(Payment__c p : inv.Payments__r){
				if(inv.CurrencyIsoCode == p.CurrencyIsoCode){
					paymentsSum += p.Amount__c;
					if(lastPaymentDate == null || lastPaymentDate < p.CreatedDate){
						lastPaymentDate = p.CreatedDate;
					}
				}
			}

			// check if should be marked as paid
			if(paymentsSum == inv.TotalWithVAT__c){
				inv.IsPaid__c = true;
				if(lastPaymentDate != null){
					inv.PaidDate__c = Date.newInstance(lastPaymentDate.year(), lastPaymentDate.month(), lastPaymentDate.day());
				}
				doUpdate = true;
			}
			try {
				if(doUpdate){
					update inv;
				}
			} catch (Exception e) {
				SyncUtils.logServiceActivity('InvoicePaymentCalculation', Cst.STATUS_ERROR, 500, 'ERROR - something wents wrong: ' + e.getMessage() + ' StackTrace: ' + e.getStackTraceString());
			}
		}
	}
	public void finish(Database.BatchableContext bc){
		// execute any post-processing operations
	}
}