({
	getData: function (cmp) {
		var hlp = this;
		var recordId = cmp.get("v.recordId");
		var action = cmp.get("c.auraGetData");
		action.setParams({quoteId:recordId});
		action.setCallback(this, function(res){
			var state = res.getState();
			if(state === 'SUCCESS'){
				var result = res.getReturnValue();
				console.log('getData(): result', result);
				cmp.set('v.quoteMdl', result);
				result.qlis.forEach(function(x){
					x.qliParent.TmpRowDiscount = Number((x.qliParent.RowDiscount__c*1).toFixed(2));
				});
				cmp.set('v.quoteMdlView', result);
				if(result.qliTransport){
					hlp.initTransport(cmp, result.qliTransport);
				}
				var rowIds = hlp.fillRowId(cmp, 'null');
				hlp.recalculateRowVal(cmp, rowIds, 'discount');
				hlp.recalculateQuoteVal(cmp);
				hlp.pageReady(cmp);
			}else{
				alert(res.getError());
			}

		});
		$A.enqueueAction(action);
	},

	closeModal : function(cmp) {
		var child = cmp.find("lookup");
		if(child){
			child.clear();
		}
		console.log('closeModal()');
        cmp.set("v.cssStyle", ".forceStyle .viewport .oneHeader.slds-global-header_container {z-index:5} .forceStyle.desktop .viewport{overflow:visible}");
		cmp.set('v.isModalOpen', false);
	},

	showModal : function(cmp){
		cmp.set("v.cssStyle", ".forceStyle .viewport .oneHeader.slds-global-header_container {z-index:0} .forceStyle.desktop .viewport{overflow:hidden}");
		cmp.set('v.isModalOpen', true);
	},

	recalculateRowVal: function(cmp, rowIds, type, value){
		var quoteMdl = cmp.get('v.quoteMdlView');
		var qtDiscount;
		if(quoteMdl.qt.QuoteDiscount__c == null){
			qtDiscount = 0;
		}else{
			qtDiscount = quoteMdl.qt.QuoteDiscount__c;
		}
		quoteMdl.qlis.forEach(function(x){
			var qliPrnt = x.qliParent;
			rowIds.forEach(function(rowId){
				if(qliPrnt.Id == rowId){
					// Total Price without discount
					var totalPriceWithoutDisc = (qliPrnt.ListPrice * qliPrnt.Quantity);
					var qliDiscount;
					if(value != null){
						qliPrnt.UnitPrice__c = value;
					}else{
						if(qliPrnt.ListPrice > 0){
							qliPrnt.UnitPrice__c = qliPrnt.ListPrice;
						}
					}
					// QLI Discount
					if(type == 'discount'){
						if(qliPrnt.RowDiscount__c == null || isNaN(qliPrnt.RowDiscount__c)){
							qliDiscount = 0;				
						}else{
							qliDiscount = qliPrnt.RowDiscount__c;
						}
						if(qliPrnt.ListPrice > 0){
							qliPrnt.UnitPrice__c = (qliPrnt.ListPrice * (1 - (qliDiscount / 100)));
						}else{
							qliPrnt.UnitPrice__c = (qliPrnt.UnitPrice__c * (1 - (qliDiscount / 100)));
							totalPriceWithoutDisc = (qliPrnt.UnitPrice__c * qliPrnt.Quantity);
						}

					}else if(type == 'unit'){
						if(qliPrnt.ListPrice > 0){
							qliPrnt.RowDiscount__c = (1 - (qliPrnt.UnitPrice__c / qliPrnt.ListPrice)) * 100;
							qliPrnt.TmpRowDiscount = Number((qliPrnt.RowDiscount__c*1).toFixed(2));
						}else{
							qliPrnt.RowDiscount__c = 0;
							qliPrnt.TmpRowDiscount = Number((qliPrnt.RowDiscount__c*1).toFixed(2));
							totalPriceWithoutDisc = (qliPrnt.UnitPrice__c * qliPrnt.Quantity);
						}
						qliDiscount = qliPrnt.RowDiscount__c;
					}

					var tmpSubtotal = totalPriceWithoutDisc * (1 - (qliDiscount / 100));
					qliPrnt.Subtotal = tmpSubtotal * (1 - (qtDiscount / 100));
					qliPrnt.RowTotalPrice__c = tmpSubtotal * (1 - (qtDiscount / 100));
					console.log('Subtotal', qliPrnt.Subtotal);
					console.log('RowTotalPrice__c', qliPrnt.RowTotalPrice__c);
					var totalDiscountValue = totalPriceWithoutDisc - qliPrnt.RowTotalPrice__c;
					qliPrnt.RowTotalDiscount__c = (totalDiscountValue / totalPriceWithoutDisc) * 100;
					qliPrnt.Discount = 0;
					console.log('QLI Discount', Number(qliPrnt.Discount.toFixed(2)));
					qliPrnt.Discount = Number(qliPrnt.Discount.toFixed(2));

					qliPrnt.UnitPrice = qliPrnt.ListPrice * (1 - (qliPrnt.RowTotalDiscount__c / 100));
				}
			});
		});
		console.log('QuoteMdl', quoteMdl);
		cmp.set('v.quoteMdlView', quoteMdl);
	},

	recalculateQuoteVal: function(cmp){
		var hlp = this;
		var quoteMdl = cmp.get('v.quoteMdlView');
		var qtSubtotal = 0;
		var qtTotal = 0;
		var totalRows = 0;

		quoteMdl.qlis.forEach(function(x){
			var totalUnitPrice = x.qliParent.ListPrice * x.qliParent.Quantity;
			totalRows += totalUnitPrice;
			qtSubtotal += (x.qliParent.ListPrice * x.qliParent.Quantity) * (1 - (x.qliParent.RowDiscount__c / 100));;
			qtTotal += x.qliParent.RowTotalPrice__c;
		});
		quoteMdl.qt.QuoteTotalDiscount__c = (1 - (qtTotal / totalRows)) * 100;
		quoteMdl.qt.Discount = 0;
		quoteMdl.qt.Subtotal__c = qtSubtotal;
		quoteMdl.qt.QuoteDiscountValue__c = qtSubtotal - qtTotal;
		console.log('Quote Total Discount', quoteMdl.qt.QuoteTotalDiscount__c);
		if(!!quoteMdl.qliTransport.Free_Shipping__c) {
			quoteMdl.qliTransport.RowTotalPrice__c = 0;
		}
		qtTotal += quoteMdl.qliTransport.RowTotalPrice__c;
		quoteMdl.qt.TotalPrice__c = qtTotal;

		console.log('recalculateFee()');
		var projectSalesFee;
		var quoteDiscount = (quoteMdl.qt.QuoteTotalDiscount__c) ? (quoteMdl.qt.QuoteTotalDiscount__c * 1).toFixed(2) : 0;
		quoteMdl.psfs.forEach(function (x){
			// if(quoteDiscount < 0){
			// 	if(x.LowerRange__c == 0){
			// 		projectSalesFee = x;
			// 	}
			// }
			// else 
			if(quoteDiscount >= x.LowerRange__c && quoteDiscount <= x.HigherRange__c){
				console.log('ProjectSalesFee', x);
				projectSalesFee = x;
			}
		});
		hlp.getCZKReward(cmp, projectSalesFee, quoteMdl.qt.CurrencyIsoCode);

		cmp.set('v.quoteMdlView', quoteMdl);
	},

	redirectToQT: function(cmp){
		var recordId = cmp.get('v.recordId');
		window.location.replace("/"+recordId);
	},

	pageReady: function(cmp){
		cmp.set('v.isLoading', false);
		cmp.set('v.isReady', true);
	},

	save: function(cmp){
		var hlp = this;
		var quoteMdl = cmp.get('v.quoteMdlView');
		var deletedRec = cmp.get('v.delRecs');
		var action = cmp.get('c.auraSave');
		cmp.set('v.isLoading', true);
		cmp.set('v.isReady', false);

		quoteMdl.qlis.forEach(function(x){
			if(x.qliParent.ListPrice > 0){
				x.qliParent.RowDiscount__c = (1 - (x.qliParent.UnitPrice__c / x.qliParent.ListPrice)) * 100;
			}else{
				x.qliParent.RowDiscount__c = 0;
			}
			if(!x.qliParent.Id.startsWith('0QL')){
				x.qliParent.Id = null;
			}
			console.log('Before save qliParent', x.qliParent.Id);
			x.qliChilds.forEach(function(y){
				if(!y.Id.startsWith('a08')){
					y.Id = null;
				}
				if(!y.QuoteLineItemId__c.startsWith('0QL')){
					y.QuoteLineItemId__c = null;
				}
			});
			if(x.qliDescriptions){
				x.qliDescriptions.forEach(function(z){
					if(!z.Id.startsWith('a0C')){
						z.Id = null;
					}
					if(z.QuoteLineItemId__c && !z.QuoteLineItemId__c.startsWith('0QL')){
						z.QuoteLineItemId__c = null;
					}
				});
			}
			
		});
		
		var delRecs = deletedRec.filter(function(x){
			return x.qliParent.Id.startsWith('0QL');
		});

		const isFreeShipping = quoteMdl.qliTransport.Free_Shipping__c == true;
		const totalShipmentPrice = this.calculateTotalShipmentPrice(cmp);

		var qlisString = JSON.stringify(quoteMdl.qlis);
        console.log('!!! ' + qlisString);
		var qtString = JSON.stringify(quoteMdl.qt);
		var qliTransport = JSON.stringify(quoteMdl.qliTransport);
		action.setParams({
						  qlmsToUpsert : qlisString, 
						  qlmsToDel : delRecs, 
						  stingQuote: qtString, 
						  qliTransportUpsert : qliTransport, 
						  qliTransportFree: isFreeShipping, 
						  shippmentTotal: totalShipmentPrice
						});
		action.setCallback(this, function(res){
			var result = res.getReturnValue();
			if(result.isSuccess){
				setTimeout(function() {
					hlp.redirectToQT(cmp);
				}, 2500);				
				//hlp.redirectToQT(cmp);
				//_notify.success($A.get("$Label.c.X_QuoteSaved"));
			}else{
				//_notify.apexError(res.getError());
				alert(result.message);
			}
		});
		$A.enqueueAction(action);
	},

	addProduct: function(cmp, prodId, productMdl){
		console.log('addProduct()');
		var hlp = this;
		var quoteMdl = cmp.get('v.quoteMdlView');
		var tmpParentId = cmp.get('v.tmpParentId');
		var tmpChildId = cmp.get('v.tmpChildId');
		var tmpDescriptionId = cmp.get('v.tmpDescriptionId');
		var qliChilds = [];
		var qliDescriptions = [];
		var newQlis = [];
		var newQli;
		var qliParentId;

		var pricebookMdl = productMdl.pbeProduct;
		var pricebookEntry = {};
		var product = {};
		var qliParent = {};
		tmpParentId += 1;
		product.Id = pricebookMdl.Product2Id;
		product.Name = pricebookMdl.Product2.Name;
		product.UnitCost__c = pricebookMdl.Product2.UnitCost__c;
		product.BusinessName__c = pricebookMdl.Product2.BusinessName__c;
		product.Type__c = pricebookMdl.Product2.Type__c;
		pricebookEntry.Id = pricebookMdl.Id;
		pricebookEntry.Product2Id = pricebookMdl.Product2Id;
		pricebookEntry.Product2 = product;
		qliParent.Id = tmpParentId.toString();
		qliParentId = tmpParentId.toString();
		qliParent.PricebookEntry = pricebookEntry;
		qliParent.QuoteId = quoteMdl.qt.Id;
		qliParent.Product2Id = prodId;
		qliParent.IsShowInQuotePDF__c = true;
		qliParent.ProductName__c = pricebookMdl.Product2.Name;
		qliParent.ProductDescriptionCZ__c = pricebookMdl.Product2.ProductDescriptionCZ__c;
		qliParent.ProductDescriptionEN__c = pricebookMdl.Product2.ProductDescriptionEN__c;
		qliParent.Description = pricebookMdl.Product2.Description;
		qliParent.Quantity = 1;
		qliParent.RelatedOptionalEquipment__c = null;
		qliParent.RowTotalDiscount__c = 0;
		qliParent.RowDiscount__c = 0;
		qliParent.IsDefault__c = pricebookMdl.Product2.IsDefault__c;
		qliParent.QuantityUnitOfMeasure__c = pricebookMdl.Product2.QuantityUnitOfMeasure;
		var unitPrice;
		switch(pricebookMdl.CurrencyIsoCode){
			case'CZK':
				unitPrice = pricebookMdl.Product2.UnitPriceCZK__c;
				break;
			case'EUR':
				unitPrice = pricebookMdl.Product2.UnitPriceEUR__c;
				break;
			case'USD':
				unitPrice = pricebookMdl.Product2.UnitPriceUSD__c;
				break;
			default:
				break;
		}
		qliParent.UnitPrice__c = unitPrice;
		qliParent.UnitPrice = unitPrice;
		qliParent.ListPrice = unitPrice;
        console.log('unitPrice ' + unitPrice);
		qliParent.PricebookEntryId = pricebookMdl.Id;
		if(productMdl.prodDescs){
			qliDescriptions = productMdl.prodDescs;
			tmpDescriptionId += 1;
			qliDescriptions.Id = tmpDescriptionId.toString();
			qliDescriptions.QuoteLineItemId__c = tmpParentId.toString();
			qliDescriptions.ProductId__c = null;
		}
		productMdl.materials.forEach(function (y){
			var qliChild = {};
			var product ={};
			tmpChildId += 1;
			product.Id = y.BundleItemId__c;
			product.Name = y.BundleItemId__r.Name;
			product.UnitCost__c = y.BundleItemId__r.UnitCost__c;
			product.BusinessName__c = y.BundleItemId__r.BusinessName__c;
			product.BusinessNameEN__c = y.BundleItemId__r.BusinessNameEN__c;
			product.Specification__c = y.BundleItemId__r.Specification__c;
			qliChild.Name = y.BundleItemId__r.Name.substring(0, 79);
			qliChild.QuoteLineItemId__c = tmpParentId.toString();
			qliChild.Id = tmpChildId.toString();
			qliChild.ProductName__c = y.BundleItemId__r.Name;
			qliChild.ProductBusinessName__c = y.BundleItemId__r.BusinessName__c;
			qliChild.Product2Id__r = product;
			qliChild.Product2Id__c = y.BundleItemId__c;
			qliChild.ProductDescriptionCZ__c = y.BundleItemId__r.ProductDescriptionCZ__c;
			qliChild.ProductDescriptionEN__c = y.BundleItemId__r.ProductDescriptionEN__c;
			qliChild.Quantity__c = y.Quantity__c;
			qliChild.Position__c = y.Position__c;
			//qliChild.Description__c = y.BundleItemId__r.Description;
			qliChild.IsEditable__c = y.IsEditable__c;
			qliChild.IsTemplateProduct__c = y.IsTemplateProduct__c;
			qliChild.IsVisible__c = y.IsVisible__c;
			qliChild.IsVisibleOnPDF__c = y.IsVisibleOnPDF__c;
			qliChild.QuantityUnitOfMeasure__c = y.BundleItemId__r.QuantityUnitOfMeasure;
			qliChilds.push(qliChild);


		});
		newQli = {qliParent, qliChilds, qliDescriptions, qliParentId};
		quoteMdl.qlis.push(newQli);

		cmp.set('v.tmpParentId', tmpParentId);	
		cmp.set('v.tmpChildId', tmpChildId);	
		cmp.set('v.isEdited', true);
		cmp.set('v.quoteMdlView',quoteMdl);
		cmp.set('v.sltProdId', '');
		console.log('Quote:addProduct()', quoteMdl);
		
		var rowIds = hlp.fillRowId(cmp, 'null');
		setTimeout(function(){ 
			hlp.recalculateRowVal(cmp, rowIds, 'discount');
			hlp.recalculateQuoteVal(cmp);
		}, 0);
		hlp.closeModal(cmp);
	},

	deleteRecord: function(cmp){
		// console.log('deleteRecord()');
		var hlp = this;
		var rowIds = [];
		var deleteRecs = cmp.get('v.delRecs');
		var quoteMdl = cmp.get('v.quoteMdlView');
		var delId = cmp.get('v.delId');
		quoteMdl.qlis.forEach(function(x){
			if(x.qliParent.Id == delId || x.qliParent.RelatedOptionalEquipment__c == delId){
				deleteRecs.push(x);					
			}
		});
		quoteMdl.qlis = quoteMdl.qlis.filter(function(x){
			return x.qliParent.Id != delId && x.qliParent.RelatedOptionalEquipment__c != delId;
		});
		cmp.set('v.quoteMdlView',quoteMdl);
		cmp.set('v.delRecs', deleteRecs);
		quoteMdl.qlis.forEach(function(x){
			rowIds.push(x.qliParent.Id);
		});
		hlp.recalculateRowVal(cmp, rowIds, 'discount');
		hlp.recalculateQuoteVal(cmp);
	},

	changeMaterial: function(cmp, sltMat){
		var sltMatId = cmp.get('v.sltMatId');
		var quoteMdl = cmp.get('v.quoteMdlView');
		var editMat = cmp.get('v.editMat');
		var editParentId = cmp.get('v.editParentId');

		console.log('SLT Material', sltMat);
		var changedMaterial;
		quoteMdl.qlis.forEach(function(x){
			if(editParentId == x.qliParent.Id){
				x.qliParent.IsDefault__c = false;
				x.qliChilds.forEach(function(y){
					if(y.Product2Id__c == editMat.Product2Id){
						y.Name = sltMat.Product2.Name;
						y.Product2Id__r.BusinessName__c = sltMat.Product2.BusinessName__c;
						y.Product2Id__r.BusinessNameEN__c = sltMat.Product2.BusinessNameEN__c;
						y.Product2Id__c = sltMat.Product2Id;
						y.Product2Id__r.Id = sltMat.Product2Id;
						y.ProductName__c = sltMat.Product2.Name;
						y.Product2Id__r.Name = sltMat.Product2.Name;
						y.Description__c = sltMat.Product2.Description;
						y.IsTemplateProduct__c = sltMat.Product2.IsTemplateProduct__c;
					}
				});
			}
		});
		console.log('QuoteMdl', quoteMdl);
		cmp.set('v.quoteMdlView', quoteMdl);
	},

	fillRowId: function(cmp, rowid){
		console.log('RowId', rowid);
		var quoteMdl = cmp.get('v.quoteMdlView');
		var rowIds = [];
		if(rowid == 'null' || rowid == null){
			console.log('Push All row Id');
			quoteMdl.qlis.forEach(function(x){
				rowIds.push(x.qliParent.Id);
			});
			console.log('RowIds', rowIds);
		}else{	
			rowIds.push(rowid);
		}
		return rowIds;
	},

	getQtDiscount : function(cmp, value){
		var quoteMdl = cmp.get('v.quoteMdlView');
		var qt = quoteMdl.qt;
		var qtDiscount = ((1 - ((qt.Subtotal__c - value) / qt.Subtotal__c)) * 100);
		console.log('getQtDiscount(): qtDiscount', qtDiscount);
		quoteMdl.qt.QuoteDiscountValue__c = value;
		quoteMdl.qt.QuoteDiscount__c = qtDiscount;
		cmp.set('v.quoteMdlView', quoteMdl);
	},

	getProduct : function(cmp, sltProdId){
		var hlp = this;
		var quoteMdl = cmp.get('v.quoteMdlView');
		var action = cmp.get('c.auraGetProductMdl');
		action.setParams({prodId: sltProdId, currencyIsoCode: quoteMdl.qt.CurrencyIsoCode});
		action.setCallback(this, function(res){
			var state = res.getState();
			console.log('getProdDesc(): state - ', state);
			if(state === 'SUCCESS'){
				var result = res.getReturnValue();
				console.log('getProdDesc(): result - ', result);
				hlp.addProduct(cmp, sltProdId, result);
			}else{
				alert(res.getError());
			}
		});	
		$A.enqueueAction(action);
	},

	getProdDesc : function(cmp, sltProdId){
		var hlp = this;
		var action = cmp.get('c.auraGetProdDescs');
		action.setParams({prodId: sltProdId});
		action.setCallback(this, function(res){
			var state = res.getState();
			console.log('getProdDesc(): state - ', state);
			if(state === 'SUCCESS'){
				var result = res.getReturnValue();
				console.log('getProdDesc(): result - ', result);
				hlp.addProduct(cmp, sltProdId, result);
			}else{
				alert(res.getError());
			}
		});	
		$A.enqueueAction(action);
	},

	recalculateTransport : function(cmp){
		console.log('recalculateTransport()');
		var hlp = this;
		var quoteMdl = cmp.get('v.quoteMdlView');
		var transportCost = cmp.get('v.transportCost');
		quoteMdl.qliTransport.TC_ShippingCost__c = (transportCost.shipping / 1.35).toFixed(2);
		console.log('Transport Shipping', quoteMdl.qliTransport.TC_ShippingCost__c);
		quoteMdl.qliTransport.TC_MaterialShippingCost__c = (transportCost.matShipping / 1.5).toFixed(2);
		quoteMdl.qliTransport.TC_AssemblyCost__c = (transportCost.assembly / 1.5).toFixed(2);
		quoteMdl.qliTransport.TC_AccommodationCost__c = (transportCost.accommodation / 1.35).toFixed(2);

		quoteMdl.qliTransport.RowTotalPrice__c = transportCost.shipping * 1 + transportCost.matShipping * 1 + transportCost.assembly * 1 +transportCost.accommodation * 1;
		quoteMdl.qliTransport.UnitPrice = transportCost.shipping * 1 + transportCost.matShipping * 1 + transportCost.assembly * 1 +transportCost.accommodation * 1;
		quoteMdl.qliTransport.UnitPrice__c = transportCost.shipping * 1 + transportCost.matShipping * 1 + transportCost.assembly * 1 +transportCost.accommodation * 1;

		transportCost.rowTotalWithoutIndex = quoteMdl.qliTransport.TC_ShippingCost__c * 1 + quoteMdl.qliTransport.TC_MaterialShippingCost__c * 1 + quoteMdl.qliTransport.TC_AssemblyCost__c * 1 + quoteMdl.qliTransport.TC_AccommodationCost__c * 1;
		
		/*var shipping = quoteMdl.qliTransport.TC_ShippingCost__c * 1.35;
		var matShipping = quoteMdl.qliTransport.TC_MaterialShippingCost__c * 1.5;
		var assembly = quoteMdl.qliTransport.TC_AssemblyCost__c * 1.5;
		var accommodation = quoteMdl.qliTransport.TC_AccommodationCost__c * 1.35;
		var rowTotal = quoteMdl.qliTransport.TC_ShippingCost__c * 1 + quoteMdl.qliTransport.TC_MaterialShippingCost__c * 1 + quoteMdl.qliTransport.TC_AssemblyCost__c * 1 + quoteMdl.qliTransport.TC_AccommodationCost__c * 1;

		quoteMdl.qliTransport.RowTotalPrice__c = shipping + matShipping + assembly + accommodation;
		quoteMdl.qliTransport.UnitPrice = shipping + matShipping + assembly + accommodation;
		quoteMdl.qliTransport.UnitPrice__c = shipping + matShipping + assembly + accommodation;
		console.log('RowTotalPrice__c', quoteMdl.qliTransport.RowTotalPrice__c);
		transportCost = {
			"shipping": shipping,
			"matShipping": matShipping,
			"assembly": assembly,
			"accommodation": accommodation,
			"rowTotalWithoutIndex": rowTotal
		};*/
		var isFreeShipping = cmp.find("freeShippingBox").get("v.checked");
		quoteMdl.qliTransport.Free_Shipping__c = isFreeShipping;
		quoteMdl.qt.x_Qli_Item_Free_Shipping__c = isFreeShipping;

		console.log('TransportCost', transportCost.shipping);
		cmp.set('v.transportCost', transportCost);
		cmp.set('v.quoteMdlView', quoteMdl);
		cmp.set('v.isEdited', true);
		hlp.recalculateQuoteVal(cmp);
	},
		calculateTotalShipmentPrice: function(cmp) {
			var transportCost = cmp.get('v.transportCost');
	
			var totalShipmentPrice = parseInt(transportCost.accommodation, 10) 
				+ parseInt(transportCost.assembly, 10) 
				+ parseInt(transportCost.matShipping, 10) 
				+ parseInt(transportCost.shipping, 10);
	
			return totalShipmentPrice;
	},

	getProductByPBE : function(cmp, productId, type){
		var hlp = this;
		var quoteMdl = cmp.get('v.quoteMdlView');
		var action = cmp.get('c.auraGetProductByPBE');
		action.setParams({prodId: productId, currencyIsoCode: quoteMdl.qt.CurrencyIsoCode});
		action.setCallback(this, function(res){
			var state = res.getState();
			if(state === 'SUCCESS'){
				var result = res.getReturnValue();
				console.log('getProductByPBE(): result', result);
				if(type == 'editItem'){
					hlp.editItm(cmp, result);
				}else{
					hlp.changeMaterial(cmp, result);
				}
			}else{
				alert(res.getError());
			}
		});
		$A.enqueueAction(action);
	},

	editItm: function(cmp, editMat){
		console.log('EditITM');
		var hlp = this;
		var quoteMdl = cmp.get('v.quoteMdlView');

		console.log('editMat2',editMat);
		if(editMat.Product2.Specification__c == null || editMat.Product2.Specification == "0"){
			cmp.set('v.sltMatSpec', "0");
		}else{
			cmp.set('v.sltMatSpec', editMat.Product2.Specification__c);
		}
		cmp.set('v.editMat', editMat);
		cmp.set('v.modalType', 'edit');
		cmp.set('v.sltMatId', null);

		hlp.showModal(cmp);
	},

	initTransport: function(cmp, qliTransport){
		var hlp = this;
		var transportCost = cmp.get('v.transportCost');
		
		var shipping = (qliTransport.TC_ShippingCost__c * 1.35).toFixed(0);
		var matShipping = (qliTransport.TC_MaterialShippingCost__c * 1.5).toFixed(0);
		var assembly = (qliTransport.TC_AssemblyCost__c * 1.5).toFixed(0);
		var accommodation = (qliTransport.TC_AccommodationCost__c * 1.35).toFixed(0);
		var rowTotal = qliTransport.TC_ShippingCost__c * 1 + qliTransport.TC_MaterialShippingCost__c * 1 + qliTransport.TC_AssemblyCost__c * 1 + qliTransport.TC_AccommodationCost__c * 1;
		var isFreeShipping = qliTransport.Free_Shipping__c;
		transportCost = {
			"shipping": shipping,
			"matShipping": matShipping,
			"assembly": assembly,
			"accommodation": accommodation,
			"rowTotalWithoutIndex": rowTotal,
			"isFreeShipping": isFreeShipping
		};
		cmp.set('v.transportCost', transportCost);
	},

	getCZKReward : function(cmp, projectSalesFee, qtCurr){
		var quoteMdl = cmp.get('v.quoteMdlView');
		var action = cmp.get('c.auraGetCZKReward');
		console.log('REWARD', projectSalesFee);
		var transportLineCost = quoteMdl.qliTransport.TC_AccommodationCost__c*1 + quoteMdl.qliTransport.TC_AssemblyCost__c*1 + quoteMdl.qliTransport.TC_MaterialShippingCost__c*1+ quoteMdl.qliTransport.TC_ShippingCost__c*1;
		var qliLineCost = 0;
		quoteMdl.qlis.forEach(function (x){
			if(x.qliParent.PricebookEntry.Product2.UnitCost__c != null){
				qliLineCost += (x.qliParent.PricebookEntry.Product2.UnitCost__c * x.qliParent.Quantity);
			}
		});
		console.log('qliLineCost', qliLineCost);
		action.setParams({totalPrice: quoteMdl.qt.TotalPrice__c, curr: qtCurr});
		action.setCallback(this, function(res){
			var state = res.getState();
			if(state === 'SUCCESS'){
				var czkTotalPrice = res.getReturnValue();
				console.log('czkTotalPrice', czkTotalPrice);
				quoteMdl.qt.ProjectSalesFee__c = (projectSalesFee.Reward__c > 0) ? projectSalesFee.Reward__c : 0;
				var projectSalesFeeValue = (czkTotalPrice - (transportLineCost + qliLineCost)) * (projectSalesFee.Reward__c / 100);
				quoteMdl.qt.ProjectSalesFeeValue__c = (projectSalesFeeValue > 0) ? projectSalesFeeValue : 0;
			}else{
				quoteMdl.qt.ProjectSalesFee__c = 0;
				quoteMdl.qt.ProjectSalesFeeValue__c = 0;
			}
			cmp.set('v.quoteMdlView', quoteMdl);
		});
		$A.enqueueAction(action);
	},

	moveOptionals: function(cmp, movedId, quoteMdl){
		
	},
})