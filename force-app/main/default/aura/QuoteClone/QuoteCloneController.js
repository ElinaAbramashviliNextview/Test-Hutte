({
    init : function(cmp, evt, hlp) {
        console.log('Init()');
        var recordId = cmp.get('v.recordId');
        console.log('RecordId', recordId);
        var action = cmp.get('c.auraGetOppCurrency');
        action.setParams({oppId : recordId});
        action.setCallback(this, function(res){
            var state = res.getState();
            if(state === 'SUCCESS'){
                var result = res.getReturnValue();
                cmp.set('v.oppCurrency', result);
                hlp.pageReady(cmp);
            }else{
                alert(res.getError());
            }
        });
        $A.enqueueAction(action);
    },

    clone: function(cmp, evt, hlp){
        cmp.set('v.isLoading', true);
        cmp.set('v.isReady', false);
        var recordId = cmp.get('v.recordId');
        var sltQuoteId = cmp.get('v.sltQuoteId');
        var action = cmp.get('c.auraClone');
        action.setParams({quoteId: sltQuoteId, oppId: recordId});
        action.setCallback(this, function(res){
            var state = res.getState();
            if(state === 'SUCCESS'){
                _notify.success("Cloned.");
                window.location.replace("/"+res.getReturnValue());
            }else{
                _notify.apexError(res.getError());
            }
        });
        $A.enqueueAction(action);
    }
})