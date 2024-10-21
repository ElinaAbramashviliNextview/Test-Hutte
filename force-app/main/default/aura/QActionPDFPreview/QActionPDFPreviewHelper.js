({
	redirectToQT: function(cmp){
		var recordId = cmp.get('v.recordId');
		window.location.replace("/"+recordId);
	},

	save: function(cmp){
		var pdfType = cmp.get('v.pdfType');
		var hlp = this;
		console.log('save()');
		var recordId = cmp.get('v.recordId');
		var action = cmp.get("c.auraSavePDF");
		action.setParams({quoteId:recordId, typePdf:pdfType});
		action.setCallback(this, function(res){
			var state = res.getState();
			if(state === 'SUCCESS'){
				console.log('Success save');
				hlp.redirectToQT(cmp);
			}
		});
		$A.enqueueAction(action);
	},

	check: function(cmp){
		var pdfType = cmp.get('v.pdfType');
		var recordId = cmp.get('v.recordId');
		var action = cmp.get('c.auraCheckCD');
		action.setParams({quoteId:recordId, typePdf:pdfType});
		action.setCallback(this, function(res){
			var state = res.getState();
			if(state === 'SUCCESS'){
				var result = res.getReturnValue();
				console.log('check(): result', result);
				cmp.set('v.canSave', result);
			}
		});
		$A.enqueueAction(action);
	},

	templateProductCheck : function(cmp){
		var pdfType = cmp.get('v.pdfType');
		var recordId = cmp.get('v.recordId');
		var action = cmp.get('c.auraCheckTmplProd');
		action.setParams({quoteId:recordId, typePdf:pdfType});
		action.setCallback(this, function(res){
			var state = res.getState();
			if(state === 'SUCCESS'){
				var result = res.getReturnValue();
				console.log('templateProdCheck(): result', result);
				cmp.set('v.hasTmplProd', result);
			}
		});
		$A.enqueueAction(action);
	}
})