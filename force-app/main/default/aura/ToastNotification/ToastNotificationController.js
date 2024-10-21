({
    doInit : function(component, event, helper) {
        var channel = '/event/ToastNotificationEvent__e';
        const replayId = -1;
          
        const empApi = component.find("empApi");
        if (empApi) {
            const callback = function (message) {
                var obj = message.data.payload;             
                component.set("v.message", obj.Message__c);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title" : "Requested Approval",
                    "message" : obj.Message__c,
                    "type" : "warning"
                });
                toastEvent.fire();
            };

            empApi.subscribe(channel, replayId, callback).then(function(newSubscription) {
            });
        }
    }
})