({
	getInitData: function(cmp){
		var action = cmp.get('c.auraGetInitData');
		console.log('getInitData()');
		action.setCallback(this, function(res){
			var state = res.getState();
			if(state === 'SUCCESS'){
				var result = res.getReturnValue();
				cmp.set('v.initData', JSON.parse(result));
				console.log('getInitData() - result', JSON.parse(result));
			}else{
				alert(res.getError());
			}
		});
		$A.enqueueAction(action);
	},

	redirectToRFT: function (cmp) {
		var recordId = cmp.get('v.recordId');
		window.location.replace("/"+recordId);
	},

	getProdDetail: function(cmp, editProdId){
		var hlp = this;
		var action = cmp.get('c.auraGetProductDetail');
		console.log('getProdDetail() - editProdId', editProdId);
		action.setParams({prodId: editProdId});
		action.setCallback(this, function(res){
			var state = res.getState();
			if(state === 'SUCCESS'){
				var result = res.getReturnValue();
				var mdlResult = JSON.parse(result);
				mdlResult.boms.forEach(function(x){
					x.$cost = x.UnitCost__c * x.Quantity__c;
				});
				cmp.set('v.rftModel', mdlResult);
				cmp.set('v.attachments', mdlResult.pAttchMdl);
				hlp.iconInsert(cmp);
				console.log('getProdDetail() - result', mdlResult.pAttchMdl);
			}else{
				alert(res.getError());
			}
		});
		$A.enqueueAction(action);
	},

	defaultProduct: function(cmp, evt, hlp){
		var tmpBOMId = cmp.get('v.tmpBOMId');

		tmpBOMId++;
		var editBOM = {};
		editBOM.Quantity__c = "0";
		editBOM.Id = tmpBOMId;
		editBOM.BundleItemId__c = "";

		cmp.set('v.editBOM', editBOM);
		cmp.set('v.tmpBOMId', tmpBOMId);
	},

	defaultProdDesc: function(cmp, evt, hlp){
		var tmpPDId = cmp.get('v.tmpPDId');

		tmpPDId++;
		var editPD = {};
		editPD.TitleCZ__c = "";
		editPD.TitleEN__c = "";
		editPD.DescriptionCZ__c = "";
		editPD.DescriptionEN__c = "";
		editPD.RowNumber__c = "0";
		editPD.Id = String(tmpPDId);

		cmp.set('v.editPD', editPD);
		cmp.set('v.tmpPDId', tmpPDId);
	},

	save: function(cmp, evt, hlp){
		var hlp = this;
		cmp.set('v.isLoading', true);
		cmp.set('v.isReady', false);
		console.log('saveBundle()');
		var rftModel = cmp.get('v.rftModel');
		var recId = cmp.get('v.recordId');
		var deletedRec = cmp.get('v.delRecs');
		var delPDs = cmp.get('v.delPDs');
		var guid = cmp.get('v.initData.guid');

		var mdl = JSON.parse(JSON.stringify(rftModel));
		console.log('saveBundle() - rftModel', mdl);
		
		if(mdl.prod.Id && !mdl.prod.Id.startsWith('01t')){
			mdl.prod.Id = null;
		}

		if(mdl.boms.length > 0){
			mdl.boms.forEach(function(x){
				if(x.Id && !x.Id.startsWith('a03')){
					x.Id = null;
				}
			});
		}

		if(mdl.prodDescs.length > 0){
			mdl.prodDescs.forEach(function(x){
				if(x.Id && !x.Id.startsWith('a0B')){
					x.Id = null;
				}
			});
		}

		var delRecs = deletedRec.filter(function(x){
			return x.Id.startsWith('a03');
		});

		var delRecsPD = delPDs.filter(function(x){
			return x.Id.startsWith('a0B');
		});
		
		console.log('saveBundle() after validate - rftModel', mdl);
		var action = cmp.get('c.auraSaveBundle');
		action.setParams({rftModel: JSON.stringify(mdl), bomsToDel: JSON.stringify(delRecs), pdToDel: JSON.stringify(delRecsPD), recordId: recId, guid: guid});
		action.setCallback(this, function(res){
			var state = res.getState();
			if(state === 'SUCCESS'){
				console.log('Saved');
				hlp.redirectToRFT(cmp);
			}
		});
		$A.enqueueAction(action);
	},

	setAttachMdl : function(cmp, attchMdl){
		console.log('setAttachMdl()', attchMdl);
		var hlp = this;
		var attachments = cmp.get('v.attachments');
		if(attachments == null){
			attachments = [];
		}
		attchMdl.forEach(function(x){
			var splitName = x.name.split('.');
			var suffix = splitName[splitName.length-1];
			var sendName = x.name;
			var shortName = x.name;
			if(x.name.length > 15){
				sendName = x.name.substring(0, 15) + '...';
			}
			if(x.name.length > 20){
				shortName = x.name.substring(0, 20) + '...';
			}
			attachments.push({fullname: x.name, id: x.id, isAttached: true, suffix: suffix, sendName: sendName, shortName: shortName, attachLink: x.attachLink});	
		});
		console.log('Added Attachments', JSON.parse(JSON.stringify(attachments)));
		cmp.set('v.attachments', attachments);
		hlp.iconInsert(cmp);
	},

	iconInsert : function(cmp){
		var hlp = this;
		var attachments = cmp.get('v.attachments');
		attachments.forEach(function(x){
			x = hlp.iconPicker(cmp, x);
		});
	},

	iconPicker : function(cmp, attch){
		attch.icon = 'doctype:attachment';
		if(attch.suffix != undefined){
			switch(attch.suffix.toUpperCase()){
				case 'EXE': attch.icon = 'doctype:exe'; break;
				case 'FLA': attch.icon = 'doctype:flash'; break;
				case 'HTML':attch.icon = 'utility:email'; break;
				case 'JS':
				case 'CS':
				case 'CSS': attch.icon = 'doctype:html'; break;
				case 'JPG':
				case 'JPEG':
				case 'TIFF':
				case 'BMP':
				case 'GIF':
				case 'PNG': attch.icon = 'doctype:image'; break;
				case 'MOV':
				case 'AVI':
				case 'MPG': 			
				case 'MPEG': attch.icon = 'doctype:video'; break;			
				case 'MP4': attch.icon = 'doctype:mp4'; break;			
				case 'PSD': attch.icon = 'doctype:pds'; break;
				case 'PDF': attch.icon = 'doctype:pdf'; break;
				case 'XLS':
				case 'XLSX': attch.icon = 'doctype:xls'; break;
				case 'PPT':
				case 'PPTX': attch.icon = 'doctype:ppt'; break;
				case 'DOC':
				case 'DOCX': attch.icon = 'doctype:word'; break;
				case 'VSS':
				case 'VDS':
				case 'VSX':
				case 'VDX': attch.icon = 'doctype:visio'; break;			
				case 'RTF': attch.icon = 'doctype:rtf'; break;
				case 'LOG':
				case 'TEXT':
				case 'TXT': attch.icon = 'doctype:txt'; break;
				case 'ZIP':
				case 'RAR': attch.icon = 'doctype:zip'; break;
			}	
		}else{
			attch.icon = 'utility:email';
		}
		return attch;
	},

	removeContentDoc : function(cmp, attachId){
		console.log('removeContentDoc');
		var action = cmp.get('c.auraRemoveContentDocument');
		action.setParams({attachId : attachId});
		action.setCallback(this, function(res){
			var state = res.getState();
			if(state === 'SUCCESS'){
			}else{
				alert(res.getError());
			}
		});
		$A.enqueueAction(action);		
	},
})