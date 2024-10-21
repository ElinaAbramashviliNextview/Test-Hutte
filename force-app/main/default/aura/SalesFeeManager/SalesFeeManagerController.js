({
    init : function(cmp, evt, hlp) {
        var action = cmp.get('c.auraGetSettings');
        action.setCallback(this, function(res){
            var state = res.getState();
            if(state === 'SUCCESS'){
                var result = res.getReturnValue();
                if(result.length < 10){
                    var restToTen = 10-result.length; 
                    for(var i = 0; i < restToTen; i++){
                        var emptyLine = {"Name": '', "LowerRange__c": '0', "HigherRange__c": '0', "Reward__c": '0'};
                        result.push(emptyLine);
                    }
                }
                cmp.set('v.salesSettings', result);
                hlp.pageReady(cmp);
            }
        });
        $A.enqueueAction(action);
    },

    saveSettings: function(cmp, evt, hlp){
        cmp.set('v.isLoading', true);
        cmp.set('v.isReady', false);
        var salesSett = cmp.get('v.salesSettings');
        var filteredSett = salesSett.filter(function(x){
            x.LowerRange__c = (x.LowerRange__c * 1);
            x.HigherRange__c = (x.HigherRange__c * 1);
            x.Reward__c = (x.Reward__c * 1);
            return x.Name != '';
        });

        console.log('Save', filteredSett);
        var action = cmp.get('c.auraSave');
        action.setParams({salesSettings: filteredSett});
        action.setCallback(this, function(res){
            var result = res.getReturnValue();
            if(result.isSuccess){
                _notify.success('Saved');
                hlp.pageReady(cmp);
			}else{
				_notify.apexError(result.message());
            }
        });
        $A.enqueueAction(action);
    }
})