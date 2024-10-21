({
	init : function(cmp, evt, hlp) {
		console.log('init()');
		cmp.set('v.isLoading', true);
		var rId = cmp.get('v.recordId');
		if(!rId){
			// called from bad location (missing recordId -> AccountId)
			// show error page and button for redirect to accounts
			cmp.set('v.isInitiatedFromOpps', true);
			cmp.set('v.isLoading', false);
			//return;
		}
		console.log('init() isInitiatedFromOpp', cmp.get('v.isInitiatedFromOpps'));
		var recordId = cmp.get('v.recordId');
		var action = cmp.get("c.auraInit");
		action.setParams({accId: recordId});
		action.setCallback(this, function(res){
			var result = res.getReturnValue();
			console.log('auraInit(): result', result);
			cmp.set('v.initData', result);
			cmp.set('v.isLoading', false);
		});
		$A.enqueueAction(action);
	},

	close : function(cmp, evt){
		if(!cmp.get('v.isInitiatedFromOpps')){
			$A.get("e.force:closeQuickAction").fire();
		}else{
			window.history.back();
		}
	},

	getDuplicates: function(cmp, evt){
		console.log('getDuplicates()');
		cmp.set('v.isLoading', true);
        var initData = cmp.get('v.initData');
		var action = cmp.get("c.auraGetDuplicates");
		var op = cmp.get('v.opp');
		var rId = cmp.get('v.recordId');
		if(rId){
			op.AccountId = rId;
		}
		if(!op.StageName){
			op.StageName = 'Qualification';
		}
        if(!op.CurrencyIsoCode){
			op.CurrencyIsoCode = initData.accountCurrency;
		}
		if(op.Country__c == '0'){
			alert('Select valid Country.');
			cmp.set('v.isLoading', false);
		}else{
			console.log('op', JSON.parse(JSON.stringify(op)));
			action.setParams({newOpp: op});
			action.setCallback(this, function(res){
				var result = res.getReturnValue();
				console.log('auraGetDuplicates(): result', result);
				cmp.set('v.duplicatesData', result);
				var dupOppRadioOpts = [];
				dupOppRadioOpts.push({'label': 'Create New Opportunity', 'value': ''});
				for( var i = 0; i < result.duplicateOpps.length; i++){
					var opp = result.duplicateOpps[i];
					dupOppRadioOpts.push({'label': 'Add to the Existing Project: ' + opp.OpportunityNo__c + ' - ' + opp.Name, 'value':opp.Id});
					//dupOppRadioOpts.push({'label': 'Create new opportunity related to the project: ' + opp.Name + ' - ' + opp.AccountNameText__c + ' [' + ((opp.Street__c)? (opp.Street__c + ',') :'') + ((opp.City__c)?opp.City__c: '') + ']' + ((opp.ParentOpportunityId__r) ? (' (' + opp.ParentOpportunityId__r.Name + ')') : ''), 'value':opp.Id});
				}
				cmp.set('v.dupOppsRadioOpts', dupOppRadioOpts);
				cmp.set('v.isLoading', false);
			});
			$A.enqueueAction(action);
		}
	},

	createOpp: function(cmp, evt){
		console.log('createOpp()');
		cmp.set('v.isLoading', true);
		var initData = cmp.get('v.initData');
		var action = cmp.get("c.auraCreateOpp");
		var op = cmp.get('v.opp');
		console.log('OPP Currency', op.CurrencyIsoCode);
		if(!op.CurrencyIsoCode){
			op.CurrencyIsoCode = initData.accountCurrency;
		}
		if(!op.StageName){
			op.StageName = 'Qualification';
		}
		var recId = cmp.get('v.recordId');
		var pId = cmp.get('v.selectedOpp');
		if(!pId){pId = null;}
		console.log('op', JSON.parse(JSON.stringify(op)), 'pId', pId);
		action.setParams({newOpp: op, parentOppId: pId});
		action.setCallback(this, function(res){
			var result = res.getReturnValue();
			console.log('createOpp(): result', result);
			cmp.set('v.createData', result);
			cmp.set('v.isLoading', false);
		});
		$A.enqueueAction(action);
	},

	/*navToAccs: function(cmp, evt){
		console.log('navToAccs()');
		var navService = cmp.find("navService");
		var pageReference = {
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Account',
                actionName: 'home'
            }
        };
        navService.navigate(pageReference);
	},*/

	redirectToNewOpp: function(cmp, evt){
		console.log('redirectToNewOpp()');
		var duplicatesRes = cmp.get("v.duplicatesData");
		var createRes = cmp.get("v.createData");
		// get created record Id, can be in either result
		var recId = duplicatesRes.newOppId || createRes.newOppId;
		var navEvt = $A.get("e.force:navigateToSObject");
		navEvt.setParams({
		  "recordId": recId,
		  "slideDevName": "Detail"
		});
		navEvt.fire();
	},

	accountChangeHandler : function(cmp, evt, hlp){
		// set currency by selected Account
		//console.log('accountChangeHandler');
		var init = cmp.get('v.initData');
		var accountId = cmp.get('v.opp').AccountId;
		var action = cmp.get('c.auraGetAccountCurrency');
		action.setParams({accountId: accountId});
		action.setCallback(this, function(res){
			var state = res.getState();
			if(state === 'SUCCESS'){
				var result = res.getReturnValue();
				init.accountCurrency = result;
				cmp.set('v.initData', init);
			}
		});
		$A.enqueueAction(action);
	},
})