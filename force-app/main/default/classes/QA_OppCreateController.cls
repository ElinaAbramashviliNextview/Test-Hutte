public class QA_OppCreateController {
	@AuraEnabled
	public static Mdl.QA_InitResponseMdl auraInit(String accId) {
		Mdl.QA_InitResponseMdl res = new Mdl.QA_InitResponseMdl();
		try {
			if(accId != null){
				res.accountCurrency = [SELECT CurrencyIsoCode FROM Account WHERE Id =: accId LIMIT 1].CurrencyIsoCode;
			}
			res.stagePickVals = Hlp.getPickVals('Opportunity', 'StageName');
			res.currencyCodes = Hlp.getPickVals('Opportunity', 'CurrencyIsoCode');
			res.countryPickVals = Hlp.getPickVals('Opportunity', 'Country2__c');
			res.countryPickVals.add(0, new Mdl.PickVal('0', '--None--'));
			res.isSuccess = true;
		} catch(Exception e) {
			res.msg = e.getMessage();
		}
		return res;
	}

	@AuraEnabled
	public static Mdl.QA_GetDuplicatesResult auraGetDuplicates(Opportunity newOpp) {
		System.debug('auraGetDuplicates() ' + newOpp);
		Mdl.QA_GetDuplicatesResult res = new Mdl.QA_GetDuplicatesResult();
		try {
			res.duplicateOpps = [SELECT Id, Name, CurrencyIsoCode, Street__c, City__c, PostalCode__c, Country__c, Country2__c, State__c, AccountId, AccountNameText__c, ParentOpportunityId__c, OpportunityNo__c, ParentOpportunityId__r.Name FROM Opportunity WHERE Street__c LIKE :newOpp.Street__c AND City__c LIKE :newOpp.City__c];
			// no posible duplicates
			if (res.duplicateOpps.size() == 0) {
				insert newOpp;
				res.isOppCreated = true;
				res.newOppId = newOpp.Id;
			}
			res.isSuccess = true;
		} catch(Exception e) {
			System.debug(e.getMessage());
			res.msg = e.getMessage();
		}
		return res;
	}

	@AuraEnabled
	public static Mdl.QA_CreateOppResult auraCreateOpp(Opportunity newOpp, Id parentOppId) {
		Savepoint sp = Database.setSavepoint();
		Mdl.QA_CreateOppResult res = new Mdl.QA_CreateOppResult();
		try {
			// No parent selected, cerate new opp directly
			if (parentOppId == null) {
				insert newOpp;
				res.newOppId = newOpp.Id;
				res.isSuccess = true;
			} else {
				// Parent opp selected, determine if parent or child is selected
				Opportunity parentOppRec = [SELECT Id, ParentOpportunityId__c FROM Opportunity WHERE Id = :parentOppId];
				// Child selected, just join under already created parent
				if (parentOppRec.ParentOpportunityId__c != null) {
					newOpp.ParentOpportunityId__c = parentOppRec.ParentOpportunityId__c;
					insert newOpp;
					res.newOppId = newOpp.Id;
					res.isSuccess = true;
				} else {
					// Standalone opp or parent selected
					Opportunity[] childOpps = [SELECT Id FROM Opportunity WHERE ParentOpportunityId__c = :parentOppRec.Id];
					// childOpps found, opp is Parent
					if (childOpps.size() > 0) {
						newOpp.ParentOpportunityId__c = parentOppRec.Id;
						insert newOpp;
						res.newOppId = newOpp.Id;
						res.isSuccess = true;
						System.debug('ChildOpp' + newOpp);
						// childOpps not found, standalone opp, create new Parent and join childs
					} else {
						// create parent
						Opportunity tmpOpp = [SELECT Id, Name, OpportunityNo__c, OpportunityNumber__c, NumericalSeries__c, ProjectNumber__c FROM Opportunity WHERE Id =: parentOppId];
						Opportunity parent = new Opportunity();
						parent.Name = Hlp.getStringWithLength('Project: ' + tmpOpp.Name, 120);
						parent.Street__c = newOpp.Street__c;
						parent.City__c = newOpp.City__c;
						parent.PostalCode__c = newOpp.PostalCode__c;
						parent.Country__c = newOpp.Country__c;
						//parent.Country2__c = newOpp.Country2__c;
						parent.State__c = newOpp.State__c;
						parent.AccountId = newOpp.AccountId;
						parent.StageName = newOpp.StageName;
						parent.CloseDate = newOpp.CloseDate;
						parent.CurrencyIsoCode = newOpp.CurrencyIsoCode;
						// Specific for project
						parent.IsProject__c = true;
						parent.OpportunityNo__c  = tmpOpp.OpportunityNo__c.substringBefore('.');
						parent.OpportunityNumber__c  = 0; // Also Project type should have Opp Number to prevent null-pointer exceptions (set to 0)
						parent.NumericalSeries__c  = tmpOpp.NumericalSeries__c;
						parent.ProjectNumber__c  = tmpOpp.ProjectNumber__c;
						System.debug('Parent' + parent);
						insert parent;
						//System.debug('After insert parent and before update child.');
						// Update child
						
						Opportunity child = new Opportunity(Id = parentOppId, ParentOpportunityId__c = parent.Id);
						update child;
						// System.debug('After update child and before insert new child.');
						// Insert new child
						newOpp.ParentOpportunityId__c = parent.Id;
						insert newOpp;
						// System.debug('After insert new child.');

						res.newOppId = newOpp.Id;
						res.isSuccess = true;
					}
				}
			}
		} catch(Exception e) {
			Database.rollback(sp);
			res.msg = e.getMessage();
		}
		return res;
	}

	@AuraEnabled
	public static String auraGetAccountCurrency(String accountId){
		return [SELECT CurrencyIsoCode FROM Account WHERE Id =: accountId LIMIT 1].CurrencyIsoCode;
	}

}