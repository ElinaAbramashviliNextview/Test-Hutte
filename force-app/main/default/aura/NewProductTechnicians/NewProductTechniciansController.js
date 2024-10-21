({
	init: function (cmp, evt, hlp) {
		var editProdId = cmp.get('v.editProdId');
		if(!editProdId){
			editProdId = null;
		}
		hlp.getInitData(cmp);
		hlp.getProdDetail(cmp, editProdId);
		hlp.defaultProduct(cmp);
		hlp.defaultProdDesc(cmp);
		cmp.set('v.isLoading', false);
		cmp.set('v.isReady', true);
	},

	backBtn : function(cmp, evt, hlp){
		console.log('Back Button');
		var isEdited = cmp.get('v.isEdited');
		if(isEdited){
			var conf = confirm('You have uncommitted work pending. Do you want continue?');
			if(conf){
				hlp.redirectToRFT(cmp);
			}
		}else{
			hlp.redirectToRFT(cmp);
		}
	},

	editBOM : function(cmp, evt, hlp){
		var rftModel = cmp.get('v.rftModel');
		var src = evt.currentTarget;
		var bomId = src.dataset.bomId;
		console.log('EditBOM() - bomId', bomId);
		var editBOM;
		rftModel.boms.forEach(function(x){
			if(x.Id == bomId){
				editBOM = x;
			}
		});
		console.log('EditBOM() - editBOM', editBOM);
		cmp.set('v.editBOM', editBOM);
	},

	editPD : function(cmp, evt, hlp){
		var rftModel = cmp.get('v.rftModel');
		var src = evt.currentTarget;
		var pdId = src.dataset.pdId;
		console.log('EditPD() - pdId', pdId);
		var editPD;
		rftModel.prodDescs.forEach(function(x){
			if(x.Id == pdId){
				editPD = x;
			}
		});
		console.log('EditPD() - editPD', editPD);
		cmp.set('v.editPD', editPD);
	},

	addBOM : function(cmp, evt, hlp){
		var rftModel = cmp.get('v.rftModel');
		var editBOM = cmp.get('v.editBOM');

		var mdl = JSON.parse(JSON.stringify(rftModel));

		var bomIds = [];
		mdl.boms.forEach(function(x){
			bomIds.push(x.Id);
		});

		console.log('addBOM() - mdl', mdl);
		if(mdl.boms.length > 0 && bomIds.includes(editBOM.Id)){
			for(var i = 0; i < mdl.boms.length; i++){
				console.log('addBOM() - editBOM', editBOM);
				if(mdl.boms[i].Id == editBOM.Id){
					mdl.boms[i] = editBOM;
					console.log('addBOM() - x', rftModel.boms[i]);
					break;
				}
			}
		}else{
			mdl.boms.push(JSON.parse(JSON.stringify(editBOM)));
		}

		var $prodCost = 0;
		mdl.boms.forEach(function(x){
			x.$cost = x.UnitCost__c * x.Quantity__c;
			$prodCost += x.$cost;
		});
		mdl.prod.UnitCost__c = $prodCost
		
		console.log('RFTModel', mdl);
		cmp.set('v.rftModel', mdl);
		cmp.set('v.isEdited', true);
		hlp.defaultProduct(cmp);
	},

	addPD : function(cmp, evt, hlp){
		var rftModel = cmp.get('v.rftModel');
		var editPD = cmp.get('v.editPD');
		var tmpPDId = cmp.get('v.tmpPDId');
		

		var mdl = JSON.parse(JSON.stringify(rftModel));
		if(!editPD.Id){
			editPD.Id = String(tmpPDId);
		}

		var pdIds = [];
		mdl.prodDescs.forEach(function(x){
			pdIds.push(x.Id);
		});

		console.log('addPD() - mdl', mdl);
		if(mdl.prodDescs.length > 0 && pdIds.includes(editPD.Id)){
			for(var i = 0; i < mdl.prodDescs.length; i++){
				console.log('addPD() - editPD', editPD);
				if(mdl.prodDescs[i].Id == editPD.Id){
					mdl.prodDescs[i] = editPD;
					console.log('addPD() - x', rftModel.prodDescs[i]);
					break;
				}
			}
		}else{
			mdl.prodDescs.push(JSON.parse(JSON.stringify(editPD)));
		}
		
		console.log('RFTModel', mdl);
		cmp.set('v.rftModel', mdl);
		cmp.set('v.isEdited', true);
		cmp.set('v.tmpPDId', tmpPDId++);
		hlp.defaultProdDesc(cmp);
	},

	changeSearch: function(cmp, evt, hlp){
		var initData = cmp.get('v.initData');
		var searchType = cmp.get('v.searchProdType');
		var searchSpec = cmp.get('v.searchProdSpec');
		var searchName = cmp.get('v.searchProdName');

		if(!searchType){
			searchType = initData.typePickVals[0].value;
		}
		console.log('SearchType', searchType);

		if(!searchSpec){
			searchSpec = initData.specPickVals[0].value;
		}
		console.log('SearchSpec', searchSpec);

		if (typeof searchName == 'undefined'){searchName = '';}
		console.log('SearchName', searchName);

		var action = cmp.get('c.auraGetSearchResult');
		action.setParams({sType: searchType, sSpec: searchSpec, sName: searchName});
		action.setCallback(this, function(res){
			var state = res.getState();
			if(state === 'SUCCESS'){
				var result = res.getReturnValue();
				cmp.set('v.searchResult', JSON.parse(result));
				console.log('getProdDetail() - result', JSON.parse(result));
			}else{
				alert(res.getError());
			}
		});
		$A.enqueueAction(action);
	},

	addProdAsBOM: function(cmp, evt, hlp){
		var rftMdl = cmp.get('v.rftModel');
		var searchResult = cmp.get('v.searchResult');
		var tmpBOMId = cmp.get('v.tmpBOMId');
		var editBOM = cmp.get('v.editBOM');
		var src = evt.currentTarget;
		var srId = src.dataset.srId;
		var srRecord = searchResult.filter(function(x){
			return x.Id == srId;
		});
		console.log('addProdAsBOM() - srRecord', srRecord);

		var bundleItem = {};
		tmpBOMId++;
		var editBOM = {};
		bundleItem.Id = srRecord[0].Id;
		bundleItem.Name = srRecord[0].Name;
		bundleItem.UnitCost__c = srRecord[0].UnitCost__c;
		bundleItem.ProductCode = srRecord[0].ProductCode;
		editBOM.QuantityUnitOfMeasure__c = srRecord[0].QuantityUnitOfMeasure;
		editBOM.BundleItemId__r = bundleItem;
		editBOM.BundleId__c = rftMdl.prod.Id;
		editBOM.BundleItemId__c = srRecord[0].Id;
		editBOM.Name = srRecord[0].Name;
		editBOM.UnitCost__c = srRecord[0].UnitCost__c;
		editBOM.Quantity__c = 1;
		editBOM.Id = String(tmpBOMId);

		console.log('addProdAsBOM() - editBOM', editBOM);
		cmp.set('v.tmpBOMId', tmpBOMId);
		cmp.set('v.editBOM', editBOM);
	},

	saveBundle: function(cmp, evt, hlp){
		var rftModel = cmp.get('v.rftModel');
		if(rftModel.prod.Type__c == "0" || rftModel.prod.QuantityUnitOfMeasure == "0"){
			alert('You cannot save bundle without Type or Quantity Unit Of Measure.');
		}else{
			hlp.save(cmp);
		}
	},

	deleteBOM : function(cmp, evt, hlp){
		var conf = confirm('Do you really want to delete the bundle item?');
		if(conf){
			var rowIds = [];
			var deleteRecs = cmp.get('v.delRecs');
			var rftMdl = cmp.get('v.rftModel');

			var src = evt.currentTarget;
			var delId = src.dataset.bomId;

			rftMdl.boms.forEach(function(x){
				if(x.Id == delId){
					deleteRecs.push(x);					
				}
			});
			rftMdl.boms = rftMdl.boms.filter(function(x){
				return x.Id != delId;
			});
            
            var $prodCost = 0;
			rftMdl.boms.forEach(function(x){
				x.$cost = x.UnitCost__c * x.Quantity__c;
				$prodCost += x.$cost;
			});
			rftMdl.prod.UnitCost__c = $prodCost
            
			cmp.set('v.rftModel',rftMdl);
			cmp.set('v.delRecs', deleteRecs);
		}
	},

	deletePD : function(cmp, evt, hlp){
		var conf = confirm('Do you really want to delete the bundle item?');
		if(conf){
			var rowIds = [];
			var delPDs = cmp.get('v.delPDs');
			var rftMdl = cmp.get('v.rftModel');

			var src = evt.currentTarget;
			var delId = src.dataset.pdId;

			rftMdl.prodDescs.forEach(function(x){
				if(x.Id == delId){
					delPDs.push(x);					
				}
			});
			rftMdl.prodDescs = rftMdl.prodDescs.filter(function(x){
				return x.Id != delId;
			});
			cmp.set('v.rftModel',rftMdl);
			cmp.set('v.delPDs', delPDs);
		}
	},

	uploadFile : function(cmp, evt, hlp){
		console.log('uploadFile()');
		var guid = cmp.get("v.initData.guid");
		var uploadedFiles = evt.getParam("files");
		console.log('Upload File', uploadedFiles);
		var docIdList = [];
		uploadedFiles.forEach(function(x){
			docIdList.push(x.documentId);
		});
		console.log('DocIdList', docIdList);
		if(docIdList.length > 0){
			var action = cmp.get("c.auraUploadFile");
			action.setParams({docIds : docIdList, guid: guid});
			action.setCallback(this, function(res){
				var state = res.getState();
				var result = res.getReturnValue();
				if(state === "SUCCESS"){
					alert('File was uploaded.');
					console.log('UploadedFiles() - result', JSON.parse(result));
					hlp.setAttachMdl(cmp, JSON.parse(result));
				}else{
					alert(res.getError());
				}
			});			
		$A.enqueueAction(action);
		}
	},

	removeAttch : function(cmp, evt, hlp){
		var attach = cmp.get('v.attachments');
		var src = evt.currentTarget;
		var attchId = src.dataset.removeAttach;

		var attch = attach.filter(function(x){return x.id != attchId});
		if(attchId.startsWith('069')){
			hlp.removeContentDoc(cmp, attchId);			
		}
		cmp.set('v.attachments', attch);
	},

	changeType : function(cmp, evt, hlp){
		var rftModel = cmp.get('v.rftModel');
		
		if(rftModel.prod.Type__c != 'V-VYROBEK' || rftModel.prod.Type__c != 'Z-ZBOZI' || rftModel.prod.Type__c != 'S-SLUZBY'){
			rftModel.prod.Family = null;
		}
		cmp.set('v.rftModel', rftModel);
	}
})