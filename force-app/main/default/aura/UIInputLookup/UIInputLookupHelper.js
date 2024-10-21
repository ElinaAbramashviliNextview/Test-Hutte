({
	// Controls
	cContainer: function(cmp){return cmp.find('container');},
	cTooltip: function(cmp){return cmp.find('tooltip');},
	cLoader: function(cmp){return cmp.find('loader');},
	cDropdown: function(cmp){return cmp.find('dropdown');},
	cFormElement: function(cmp){return cmp.find('formElement');},
	cResultList: function(cmp){return cmp.find('resultList');},
	cInput: function(cmp){return cmp.find('input');},

	open: function(cmp){
    	var isOpen = cmp.get('v.isOpen');
    	var isSelected = cmp.get('v.isSelected');
		if(isOpen || isSelected) return;
    	cmp.set('v.isOpen', true);

		var that = this;
    	var el = this.cInput(cmp).getElement();
        function windowClickHandler(){
			if (cmp.isValid()) {
        		window.removeEventListener("click", windowClickHandler);
        		el.removeEventListener( "click", elementClickHandler );
        		that.close(cmp);
    		}
        }
        function elementClickHandler(event){
            event.stopPropagation();
        }                        
        el.addEventListener('click', elementClickHandler );
        window.addEventListener('click', windowClickHandler );
	},
	close: function(cmp){
		console.log('cmp:lookup','close()');
		cmp.set('v.isOpen', false);
		cmp.set('v.hasFocus', false);
	},
	search: function(cmp, evt) {
		var hlp = this;
		if(!this.isWritable(cmp)) return;
		
    	var isSelected = cmp.get('v.isSelected');
    	if(isSelected) return;
		var that = this;
		var searchText = cmp.find('input').getElement().value.toLowerCase();

		// API - Override search text if called externally
		if(evt.getParam){
	        var evtParams = evt.getParam('arguments');
	        if (params) {
	            searchText = evtParams.text||'';
	        }
		}

		var sobject = cmp.get("v.sobject");
		var findBy = cmp.get("v.findBy");
		var fields = cmp.get("v.fields");
		var displayFields = cmp.get("v.displayFields");


		// If data provided, skip apex call
		var hasDataset = cmp.get('v.hasDataset');
		if(hasDataset){
			var data = cmp.get('v.dataset');
			console.log('cmp:lookup','using dataset', data);
			var filtered = data || [];
			if(searchText && findBy && findBy.length){
				var prop = findBy[0]; 
				filtered = filtered.filter(function(x){ return x[prop] &&  (typeof x[prop] === 'string') && x[prop].toLowerCase().indexOf(searchText.toLowerCase()) > -1 ;});
			}
			processResults(filtered);
	    	return;
		}

    	if(displayFields && displayFields.length){
            if(fields && fields.length){
                displayFields.forEach(function(x){
                    if(fields.indexOf(x) == -1){fields.push(x);}
                });
            }else{
                fields = displayFields;  
            }
        }  
		var params = {so: sobject, q:searchText, findBy: findBy, fields: fields, andClause: cmp.get("v.andClause"), showRecent: cmp.get("v.showRecent"), excludedIds: cmp.get("v.excludedIds"), orderBy: cmp.get('v.orderBy')};

		console.log('cmp:lookup','search()', params);
    	cmp.set('v.isLoading', true);
		var apexAction = cmp.get('c.apexSearch');
    	apexAction.setParams(params);
    	apexAction.setCallback(this, function(res){
        	var state = res.getState();
    		cmp.set('v.isLoading', false);
	        if (cmp.isValid() && state === 'SUCCESS') {
	        	var results = res.getReturnValue();
	        	console.log('cmp:lookup','search()','result', results);
    			processResults(results);
	        }else{
    			console.warn('cmp:lookup','lookup', state);
                var errors = res.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.warn('cmp:lookup',"Error message: " + errors[0].message);
                    }
                } else {
                    console.warn('cmp:lookup',"Unknown error");
                }
	        }
    	});


    	function processResults(results) {
        	console.log('cmp:lookup','search()','result', results);
        	// create meta info
        	if(displayFields && displayFields.length){
    	    	results.forEach(function(r, idx){
    	    		r.$meta = ''; // Clear (would may be already populated if dataset used)
    	    		displayFields.forEach(function(df){
    	    			var rf;
    	    			var ff = df.split('.');
    	    			var prop = df;
    	    			if(ff.length>1){
    	    				rf = ff[0];
    	    				df = ff[1];
    	    				prop = [rf];
    	    			}

    	    			if(r.hasOwnProperty(prop)){
	    	    			var val = (rf) ? (r[rf][df] || 'N/A') : r[df] || 'N/A';
		    	    		if(!r.$meta){
		    	    			r.$meta = '<span title="'+df+'">'+ val + '</span>';
		    	    		}else{
		    	    			r.$meta += ' • <span title="'+df+'">'+ val + '</span>';
		    	    		}
	    	    		}
    	    		});
    	    		if(!r.$meta) r.$meta = 'N/A';
    	    	});
        	}
	    	cmp.set('v.results', results);
	    	hlp.doHighlight = true;
			hlp.open(cmp);
    	}

    	$A.enqueueAction(apexAction);
	},
    flattenObject: function(hlp, ob) {
        var toReturn = {};

        for (var i in ob) {
            if (!ob.hasOwnProperty(i)) continue;

            if ((typeof ob[i]) == 'object') {
                var flatObject = hlp.flattenObject(hlp, ob[i]);
                for (var x in flatObject) {
                    if (!flatObject.hasOwnProperty(x)) continue;

                    toReturn[i + '.' + x] = flatObject[x];
                }
            } else {
                toReturn[i] = ob[i];
            }
        }
        return toReturn;
    },
	select: function(cmp, evt, hlp){
		var rId = evt.target.dataset.recordId;

		console.log('cmp:lookup','select()', rId, evt.target);
		if(!this.isWritable(cmp)) return;
    	var results = cmp.get('v.results');
    	var record = results.filter(function(x){return x.Id === rId;})[0];
    	if(record){
			cmp.set('v.isInternalSet', true); // Set Internal set flag, so record change handler may ommit action.
            var values = hlp.flattenObject(hlp, record);
	    	if(record.SmallPhotoUrl){cmp.set('v.thumb', record.SmallPhotoUrl);}
	    	
	    	cmp.set('v.isSelected', true);
	    	cmp.set('v.text', values[cmp.get('v.nameField')]);
	    	cmp.set('v.prevValue', cmp.get('v.value')); // Set prev value from current selection
            cmp.set('v.value', record.Id);
	    	cmp.set('v.record', record);
	    	this.broadcastChange(cmp, evt);
    	}else{
    		console.warn('cmp:lookup','lookup record not found');
    	}
	},	
	clear : function(cmp, evt, skipRefSet, externalChange) {
		console.log('cmp:lookup','clear()', 'bcast:',!externalChange);
		if(!externalChange){
			cmp.set('v.isInternalSet', true); // Set Internal set flag, so record change handler may ommit action.
		}
    	cmp.set('v.isSelected', false);
    	cmp.set('v.text', '');
    	cmp.set('v.value', '');
    	if(!skipRefSet) cmp.set('v.record', {});
    	if(!externalChange) this.broadcastChange(cmp, evt);
	},
	isWritable: function(cmp){
		var isReadonly = cmp.get('v.readonly');
		var isDisabled = cmp.get('v.disabled');
		var rw = (!isReadonly && !isDisabled);
		if(!rw){
			console.warn('cmp:lookup','readonly or disabled');
		}
		return rw;
	},
	broadcastChange: function(cmp, evt, record){
		console.log('cmp:lookup','broadcastChange()');
		var key = cmp.get("v.key");
		if(key){
			var e = cmp.getEvent("lookupChangedEvent");
			var parentId = cmp.get("v.parentId");
			var prevValue = cmp.get("v.prevValue");
			var value = cmp.get("v.value");
			var field = cmp.get("v.field");
			var params = {key:key, recordId: parentId, changes:[]};
			if(field) params.changes.push({field:field, oldValue:prevValue, newValue: value});
	    	e.setParams(params);
			e.fire();			
		}
	},


	rerender: function(cmp){
		var tb = this.cInput(cmp);
    	var dd = this.cDropdown(cmp);
    	var rl = this.cResultList(cmp);

		var isOpen = cmp.get('v.isOpen');
		var hasFocus = cmp.get('v.hasFocus');
		var isLoading = cmp.get('v.isLoading');
		

		var cont = this.cContainer(cmp);
		if(isOpen){
	    	$A.util.addClass(dd, 'slds-is-open');
	    	$A.util.removeClass(dd, 'slds-combobox-lookup');			
	    	$A.util.removeClass(rl, 'slds-hide');
		}else{
			hasFocus = false;
	    	$A.util.removeClass(dd, 'slds-is-open');
	    	$A.util.addClass(dd, 'slds-combobox-lookup');
	    	$A.util.addClass(rl, 'slds-hide');
		}

		var fe = this.cFormElement(cmp);
		var isSelected = cmp.get('v.isSelected');
		if(isSelected){
	    	$A.util.addClass(fe, 'slds-input-has-icon_left-right');
	    	$A.util.removeClass(fe, 'slds-input-has-icon_right');
		}else{
		   	$A.util.removeClass(fe, 'slds-input-has-icon_left-right');
			$A.util.addClass(fe, 'slds-input-has-icon_right');	
		}

		if(tb && tb.getElement()){
			var isDisabled = cmp.get('v.disabled');
			if(isDisabled){
				tb.getElement().setAttribute("disabled", "disabled");
			}
			else{
				tb.getElement().removeAttribute("disabled");
			}
		}

		if(hasFocus){
        	$A.util.addClass(cont,'slds-has-input-focus');		
		}else{
        	$A.util.removeClass(cont,'slds-has-input-focus');		
		}		
		
		// Highlight
		if(isOpen && this.doHighlight){
			this.doHighlight = false;
		    var rlEl = rl.getElement();
		    if(rlEl){
				var text = cmp.find('input').getElement().value.toLowerCase();
				var textLen = text.length;
				// Setting timeout cause at this point, DOM holds prev search rows
				setTimeout(function(){
					var rows = rlEl.getElementsByClassName('slds-listbox__option-text_entity');
					if(text && rows.length){
				        for (var i = rows.length - 1; i >= 0; i--) {
				            var innerHTML = rows[i].innerHTML;
				            var index = innerHTML.toLowerCase().indexOf(text);
				            if (index >= 0 ){ 
				                innerHTML = innerHTML.substring(0,index) + "<span class='tspc-highlight'>" + innerHTML.substring(index,index+textLen) + "</span>" + innerHTML.substring(index + textLen);
				                rows[i].innerHTML = innerHTML;
				            }              
			            }
					}
				},50);
		    }
		}
	}
});