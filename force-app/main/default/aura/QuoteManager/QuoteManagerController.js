({
	init: function (cmp, evt, hlp) {
		hlp.getData(cmp);
	},

	closeMod:function(cmp, evt, hlp){
		hlp.closeModal(cmp);
	},

	// Show modal for change material
	editItem: function(cmp, evt, hlp){
		var src = evt.currentTarget;
		var prodId = src.dataset.prodId;
		var parentId = src.dataset.parentId;
		console.log('editItem(): prodId', prodId);
		cmp.set('v.editParentId', parentId); 
		hlp.getProductByPBE(cmp, prodId, 'editItem');
	},

	editTransport: function(cmp, evt, hlp){
		console.log('Edit Transport');
		cmp.set('v.modalType', 'transport');
		hlp.recalculateTransport(cmp);
		hlp.showModal(cmp);
	},

	changeTransport : function(cmp, evt, hlp){
		hlp.recalculateTransport(cmp);
	},

	showDesc: function(cmp, evt, hlp){
		evt.preventDefault();
		cmp.set('v.modalType', 'showDesc');
		var quoteMdl = cmp.get('v.quoteMdlView');
		var src = evt.currentTarget;
		var rowId = src.dataset.rowId;
		var descToShow;
		var qliDescs = [];
		quoteMdl.qlis.forEach(function(x){
			if(x.qliParent.Id == rowId){
				if(quoteMdl.qt.Language__c == "cs"){
					descToShow = x.qliParent.ProductDescriptionCZ__c;
					if(x.qliDescriptions){
						x.qliDescriptions.forEach(function(y){
							var desc = {title :y.TitleCZ__c, description :y.DescriptionCZ__c, rowNum: y.RowNumber__c};
							qliDescs.push(desc);
						});
					}
				}else if(quoteMdl.qt.Language__c == "en_GB"){
					descToShow = x.qliParent.ProductDescriptionEN__c;
					if(x.qliDescriptions){
						x.qliDescriptions.forEach(function(y){
							var desc = {title :y.TitleEN__c, description :y.DescriptionEN__c, rowNum: y.RowNumber__c};
							qliDescs.push(desc);
						});
					}
				}
			}
		});
		cmp.set('v.descToShow', descToShow);
		console.log('QLI Description', qliDescs);
		cmp.set('v.qliDescs', qliDescs);
		hlp.showModal(cmp);
	},

	// Delete Modal
	deleteItem: function(cmp, evt, hlp){
		cmp.set('v.modalType', 'delete');
		var src = evt.currentTarget;
		var delId = src.dataset.btnId;
		cmp.set('v.delId', delId);
		hlp.showModal(cmp);
	},

	deleteOptionalItem: function(cmp, evt, hlp){
		cmp.set('v.modalType', 'deleteOptional');
		var src = evt.currentTarget;
		var delOptId = src.dataset.btnId;
		var delParentOptId = src.dataset.parentId;
		cmp.set('v.delOptId', delOptId);
		cmp.set('v.delParentOptId', delParentOptId);
		hlp.showModal(cmp);
	},

	// Change Parent values
	changeValue: function(cmp, evt, hlp){
		console.log('ChangeValue()');
		var quoteMdl = cmp.get('v.quoteMdlView');
		var src = evt.currentTarget;
		var val = src.value;
		var changeType = src.dataset.changeType;
		var disc;
		var quant;
		var rowid = src.dataset.rowId;
		var rowIds = hlp.fillRowId(cmp, rowid);
		var type = src.dataset.type;
		if(!type){
			type = 'discount';
		}
		if(type == 'discount'){
			quoteMdl.qlis.forEach(function(x){
				if(x.qliParent.Id == rowid){
					x.qliParent.RowDiscount__c = x.qliParent.TmpRowDiscount;
				}
			});
		}
		if(changeType == "qtDiscVal"){
			hlp.getQtDiscount(cmp, val);
			val = null;
		}
		console.log('VALUE', val);
		hlp.recalculateRowVal(cmp, rowIds, type, val);
		hlp.recalculateQuoteVal(cmp);
		cmp.set('v.isEdited', true);
	},

	// Back button
	backBtn: function(cmp, evt, hlp){
		console.log('Back Button');
		var isEdited = cmp.get('v.isEdited');
		if(isEdited){
			var conf = confirm('You have uncommitted work pending. Do you want continue?');
			if(conf){
				hlp.redirectToQT(cmp);
			}
		}else{
			hlp.redirectToQT(cmp);
		}
	},
	
	saveQuote: function(cmp, evt, hlp){
		var isDiscountHigher = false;
		var quoteMdl = cmp.get('v.quoteMdlView');
		quoteMdl.qlis.forEach(function(x){
			if(Number((x.qliParent.RowTotalDiscount__c*1).toFixed(2)) > quoteMdl.accountDiscount){
				isDiscountHigher = true;
			}
		});
		if(isDiscountHigher){
			console.log('Discount Reason', quoteMdl.qt.DiscountReason__c);
			if(!quoteMdl.qt.DiscountReason__c && (quoteMdl.qt.DiscountReason__c == null || quoteMdl.qt.DiscountReason__c == '') && quoteMdl.needAppprove){
				alert('Discount is greater than Maximum Allowed Discount. There must be filled Discount Reason.');
			}
			else{
				var conf = confirm('Total Row Discount is greater than Maximum Allowed Discount: ' + quoteMdl.accountDiscount + '%. Send to Approve?');
				if(conf){
					hlp.save(cmp);
				}
			}
		}else{
			hlp.save(cmp);
		}
	},

	// Handle Dropdown button 
	handleSelect: function(cmp, evt, hlp){
		var selectedButton = evt.getParam("value");
		switch(selectedButton){
			case 'addProduct':
				cmp.set('v.modalType', selectedButton);
				hlp.showModal(cmp);
				break;
		}
	},

	showProdMod : function (cmp, evt, hlp){
		cmp.set('v.modalType', 'addProduct');
		cmp.set('v.sltProdFam', '0');
		hlp.showModal(cmp);
	},

	// Add new product to model
	addNewLine: function(cmp, evt, hlp){
		var prodId = cmp.get('v.sltProdId');
		hlp.getProduct(cmp,prodId);
		//hlp.getProdDesc(cmp, prodId);
	},

	// Delete record from model
	deleteRec: function(cmp, evt, hlp){
		console.log('deleteRec()');		
		hlp.deleteRecord(cmp);
		hlp.closeModal(cmp);
	},

	// Delete optional record from model
	deleteOptionalRec: function(cmp, evt, hlp){
		hlp.deleteOptionalRecord(cmp);
		hlp.closeModal(cmp);
	},

	// Select other material, same Type
	editMaterial: function(cmp, evt, hlp){
		console.log('editMaterial()');
		cmp.set('v.isEdited', true);
		var sltMatId = cmp.get('v.sltMatId');
		hlp.getProductByPBE(cmp, sltMatId, 'changeMat');
		hlp.closeModal(cmp);
	},

	rounding : function(cmp, evt, hlp){
		console.log('Rounding');
		var quoteMdl = cmp.get('v.quoteMdlView');
		var src = evt.target;
		var rowId = src.dataset.rowId;
		quoteMdl.qlis.forEach(function(x){
			var qliPrnt = x.qliParent;
			if(qliPrnt.Id == rowId){
				qliPrnt.TmpRowDiscount = Number((qliPrnt.RowDiscount__c*1).toFixed(2));
				//qliPrnt.RowDiscount__c = (qliPrnt.RowDiscount__c * 1).toFixed(2);
				qliPrnt.UnitPrice__c = (qliPrnt.UnitPrice__c * 1).toFixed(2);
			}
		});
		cmp.set('v.quoteMdlView', quoteMdl);
	},

	roundQTDisc : function(cmp, evt, hlp){
		var quoteMdl = cmp.get('v.quoteMdlView');
		quoteMdl.qt.QuoteDiscount__c = (quoteMdl.qt.QuoteDiscount__c * 1).toFixed(2);
		quoteMdl.qt.QuoteDiscountValue__c = (quoteMdl.qt.QuoteDiscountValue__c * 1).toFixed(2);
		cmp.set('v.quoteMdlView', quoteMdl);
	},

	resetTransport : function(cmp, evt, hlp){
		var quoteMdl = cmp.get('v.quoteMdlView');
		var transportCost = cmp.get('v.transportCost');
		transportCost.shipping = 0;
		transportCost.matShipping = 0;
		transportCost.assembly = 0;
		transportCost.accommodation = 0;
		cmp.set('v.quoteMdlView', quoteMdl);
		hlp.recalculateTransport(cmp);
	},

	moveUp : function(cmp, evt, hlp){
		var oldIndex = -1;
		var newIndex;
		var movedElement;
		var quoteMdl = cmp.get('v.quoteMdlView');
		var src = evt.currentTarget;
		var movedId = src.dataset.btnId;
		for(var i = 0; i < quoteMdl.qlis.length; i++){
			if(quoteMdl.qlis[i].qliParent.Id == movedId){
				oldIndex = i;
				movedElement = quoteMdl.qlis[i];
				break;
			}
		}
		newIndex = oldIndex;
		for(var i = oldIndex - 1; i >= 0; i--){
			if(!quoteMdl.qlis[i].qliParent.RelatedOptionalEquipment__c){
				newIndex--;
				break;
			}else{
				newIndex--;
			}
		}
				
		var optionalCount = 0;
		for(var i = oldIndex; i < quoteMdl.qlis.length; i++){
			if(quoteMdl.qlis[i].qliParent.RelatedOptionalEquipment__c == movedElement.qliParent.Id){
				optionalCount ++;
			}
		}
	
		for(var i = oldIndex + optionalCount; i >= oldIndex; i--){
			quoteMdl.qlis.splice(newIndex, 0, quoteMdl.qlis[oldIndex + optionalCount]);
			quoteMdl.qlis.splice(oldIndex + optionalCount + 1, 1);
		}
		
		console.log('moveUP', JSON.parse(JSON.stringify(quoteMdl)));
		cmp.set('v.quoteMdlView', JSON.parse(JSON.stringify(quoteMdl)));
		cmp.set('v.isEdited', true);
	},

	moveDown : function(cmp, evt, hlp){
		var oldIndex = -1;
		var newIndex;
		var movedElement;
		var quoteMdl = cmp.get('v.quoteMdlView');
		var src = evt.currentTarget;
		var movedId = src.dataset.btnId;

		// Get record old position
		for(var i = 0; i < quoteMdl.qlis.length; i++){
			if(quoteMdl.qlis[i].qliParent.Id == movedId){
				oldIndex = i;
				movedElement = quoteMdl.qlis[i];
				break;
			}
		}

		// Set record new position
		newIndex = oldIndex + 2;
		var isIndexSet = false;
		for(var i = oldIndex + 1; i < quoteMdl.qlis.length; i++){
			if(!quoteMdl.qlis[i].qliParent.RelatedOptionalEquipment__c){
				if(isIndexSet){
					break;
				}else{
					isIndexSet = true;
				}
			}else{
				newIndex++;
			}
		}

		// Insert record to new position
		quoteMdl.qlis.splice(newIndex, 0, movedElement);
		
		// Move Optionals to RelatedOptionalEquipment
		var optionalCount = 0;
		for(var i = 0; i < quoteMdl.qlis.length; i++){
			if(i == newIndex){
				break;
			}else{
				if(quoteMdl.qlis[i].qliParent.RelatedOptionalEquipment__c == movedElement.qliParent.Id){
					optionalCount ++;
					quoteMdl.qlis.splice(newIndex + optionalCount, 0, quoteMdl.qlis[i]);
				}
			}
		}
		
		// Delete record and Optionals from their old position
		quoteMdl.qlis.splice(oldIndex, 1);
		for(var i = 0; i < optionalCount; i++){
			quoteMdl.qlis.splice(oldIndex, 1);
		}
		
		// JSON parse and stringify - repair bug
		console.log('moveOptDown', JSON.parse(JSON.stringify(quoteMdl)));
		cmp.set('v.quoteMdlView', JSON.parse(JSON.stringify(quoteMdl)));
		cmp.set('v.isEdited', true);
	},

	addOptional: function(cmp, evt, hlp){
		var constProduct = cmp.get('v.constProduct');
		var quoteMdl = cmp.get('v.quoteMdlView');
		var src = evt.currentTarget;
		var optionalId = src.dataset.btnId;
		var optionalCount = 0;
		// Get index of adding optional
		for(var i = quoteMdl.qlis.length-1; i >= 0; i--){
			if(quoteMdl.qlis[i].qliParent.Id == optionalId && i > 0){

				// Find first V-VYROBEK
				for(var j = i - 1; j >= 0; j--){
					console.log('NEXT TYPE', quoteMdl.qlis[j].qliParent.PricebookEntry.Product2.Type__c);
					if(quoteMdl.qlis[j].qliParent.PricebookEntry.Product2.Type__c == constProduct){
						console.log('Next Record is V-VYROBEK');
						quoteMdl.qlis[i].qliParent.RelatedOptionalEquipment__c = quoteMdl.qlis[j].qliParent.Id;
						quoteMdl.qlis.splice(j + 1, 0, quoteMdl.qlis[i]);
						quoteMdl.qlis.splice(i + 1, 1);
						break;
					}else if(quoteMdl.qlis[j].qliParent.RelatedOptionalEquipment__c){
						console.log('Next Record is příplatek přiřazený');
						quoteMdl.qlis[i].qliParent.RelatedOptionalEquipment__c = quoteMdl.qlis[j].qliParent.RelatedOptionalEquipment__c;
						quoteMdl.qlis.splice(j + 1, 0, quoteMdl.qlis[i]);
						quoteMdl.qlis.splice(i + 1, 1);
						break;
					}
				}
				break;
			}
		}
		console.log('addOptional', JSON.parse(JSON.stringify(quoteMdl)));
		cmp.set('v.quoteMdlView', JSON.parse(JSON.stringify(quoteMdl)));
		cmp.set('v.isEdited', true);
	},

	removeOptional : function(cmp, evt, hlp){
		console.log('removeOptional');
		var quoteMdl = cmp.get('v.quoteMdlView');
		var src = evt.currentTarget;
		var optionalId = src.dataset.optId;
		var parentId = src.dataset.parentId;
		console.log('QLI Optionals', optionalId);
		for(var i = 0; i < quoteMdl.qlis.length; i++){
			if(quoteMdl.qlis[i].qliParent.Id == optionalId){
				quoteMdl.qlis[i].qliParent.RelatedOptionalEquipment__c = null;
				break;
			}
		}
		console.log('removeOptional', quoteMdl);
		cmp.set('v.quoteMdlView', quoteMdl);
		cmp.set('v.isEdited', true);
	},
})