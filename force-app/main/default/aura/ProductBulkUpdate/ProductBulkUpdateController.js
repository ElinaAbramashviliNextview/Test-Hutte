({
    init: function (cmp, evt, hlp) {
		hlp.getInitData(cmp);
		
	},

    changeFilter : function(cmp,evt,hlp){
        hlp.getFilterData(cmp);
    },

    sendExport : function(cmp, evt, hlp){
        console.log('SendExport');
        var searchResult = cmp.get('v.searchResult');
        var email = cmp.get('v.email');
        var action = cmp.get('c.auraSendExport');
        action.setParams({exportData: JSON.stringify(searchResult), emailAddr: email});
        action.setCallback(this, function(res){
            if(res.getState() === 'SUCCESS'){   
                var result = res.getReturnValue();
                alert('File with exported Products will be sent to entered email.\n It can take a few minutes it depends on number of records.');
            }
        });
        $A.enqueueAction(action);
    },

    handleUploadFinished : function(cmp,evt,hlp){
        var guid = cmp.get('v.initData.guid');
		var uploadedFiles = evt.getParam('files');
		console.log('Upload File', uploadedFiles);
		if(uploadedFiles[0].documentId){
            cmp.set('v.docId', uploadedFiles[0].documentId);
			var action = cmp.get('c.auraProductProcessing');
			action.setParams({docId : uploadedFiles[0].documentId});
			action.setCallback(this, function(res){
				var state = res.getState();
				if(state === 'SUCCESS'){
					alert('File was uploaded.');
					var result = res.getReturnValue();
                    console.log('handleUploadFinished() - result', JSON.parse(result).query);
                    cmp.set('v.searchResult', JSON.parse(JSON.parse(result).query));
                    cmp.set('v.shortSearchView', JSON.parse(JSON.parse(result).shortQuery));
                    cmp.set('v.searchResultCount', JSON.parse(result).recordCount);
				}else{
					alert(res.getError());
				}
			});			
		    $A.enqueueAction(action);
		}
    },

    updateData : function(cmp,evt,hlp){
        cmp.set('v.isLoading', true);
		cmp.set('v.isReady', false);
        var docId = cmp.get('v.docId');
        var email = cmp.get('v.email');
        console.log('Email', email);
        var action = cmp.get('c.auraUpdateProducts');
        action.setParams({docId: docId, eAddr: email});
        action.setCallback(this, function(res){
            var state = res.getState();
            if(state === 'SUCCESS'){
                var result = res.getReturnValue();
                hlp.getFilterData(cmp);
                cmp.set('v.docId', null);
                cmp.set('v.initData.isImportEnabled', false);
                alert('Products will be updated. Email will be sent to your email address with information after update.');
            }
        });
        $A.enqueueAction(action);
    },

    manualBackup : function(cmp){
        var action = cmp.get('c.auraManualBackup');
        action.setCallback(this, function(res){
            var state = res.getState();
            if(state === 'SUCCESS'){
                alert('Manual export to G-Drive scheduled. This may take a while.');
            }
        });
        $A.enqueueAction(action);
    },
})