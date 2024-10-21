({
    getInitData: function(cmp){
        var hlp = this;
		var action = cmp.get('c.auraGetInitData');
		console.log('getInitData()');
		action.setCallback(this, function(res){
			var state = res.getState();
			if(state === 'SUCCESS'){
				var result = res.getReturnValue();
				cmp.set('v.initData', JSON.parse(result));
				console.log('getInitData() - result', JSON.parse(result));
                hlp.getFilterData(cmp);
			}else{
				alert(res.getError());
			}
		});
		$A.enqueueAction(action);
	},

    getFilterData: function(cmp){
		cmp.set('v.isLoadingTable', true);
		cmp.set('v.isReadyTable', false);
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
				console.log('getProdDetail() - result', JSON.parse(result).query);
				cmp.set('v.searchResult', JSON.parse(JSON.parse(result).query));
				cmp.set('v.shortSearchView', JSON.parse(JSON.parse(result).shortQuery));
                cmp.set('v.searchResultCount', JSON.parse(result).recordCount);
				cmp.set('v.isLoadingTable', false);
				cmp.set('v.isReadyTable', true);
				cmp.set('v.isLoading', false);
				cmp.set('v.isReady', true);
			}else{
				alert(res.getError());
			}
		});
		$A.enqueueAction(action);
	},
})