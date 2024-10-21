({
	init: function (cmp, evt, hlp) {
		var rftId = cmp.get('v.recordId');
		var action = cmp.get('c.auraGetProds');
		action.setParams({recordId : rftId});
		action.setCallback(this, function(res){
			var state = res.getState();
			if(state === 'SUCCESS'){
				var result = res.getReturnValue();
				console.log('Result', JSON.parse(result));
				cmp.set('v.prodList', JSON.parse(result));
				cmp.set('v.isLoading', false);
				cmp.set('v.isReady', true);
			}else{
				alert(res.getError());
			}
		});
		$A.enqueueAction(action);
	},

	editProduct: function(cmp, evt, hlp){
		var recordId = cmp.get('v.recordId');
		var src = evt.currentTarget;
		var prodId = src.dataset.prodId;
		var evt = $A.get("e.force:navigateToComponent");
		evt.setParams({
			componentDef: "c:NewProductTechnicians",
			componentAttributes: {
				recordId: recordId, editProdId: prodId
			}
		});
		evt.fire(); 
		/*var vfURL = '/apex/NewProductTechnicians?id=' + recordId + '&prodId=' + prodId;
		console.log('Url', vfURL);
		var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
                "url": vfURL
        });
        urlEvent.fire();*/
	},

	newProduct : function(cmp, evt, hlp){
		var recordId = cmp.get('v.recordId');
		var evt = $A.get("e.force:navigateToComponent");
		evt.setParams({
			componentDef: "c:NewProductTechnicians",
			componentAttributes: {
				recordId: recordId	
			}
		});
		evt.fire();
	},
	
	deleteProduct: function(cmp, evt, hlp){
		var conf = confirm('Do you really want to delete the bundle?');
		if(conf){
			var src = evt.currentTarget;
			var prodId = src.dataset.prodId;
			var recId = cmp.get('v.recordId');
			var action =  cmp.get('c.auraDeleteProduct');
			action.setParams({prodId: prodId, recordId: recId});
			action.setCallback(this, function(res){
				var state = res.getState();
				if(state === 'SUCCESS'){
					var result = res.getReturnValue();
					console.log('Result', JSON.parse(result));
					cmp.set('v.prodList', JSON.parse(result));
					 $A.get('e.force:refreshView').fire();
				}
			});
			$A.enqueueAction(action);
		}
	}
})