({
	init : function(cmp, evt, hlp) {
		// Generate id if not provided
		var id = cmp.get('v.id');
		if(!id){cmp.set('v.id', 'G' + (new Date()).getTime() + 'X' + Math.random().toString(36).substr(2, 9));}

		// Set init value
		var record = cmp.get('v.record');
		var value = cmp.get('v.value');
		if(record && record.Id){
			// If relation exist used it
			cmp.set('v.value', record.Id);
			cmp.set('v.text', record.Name || record.Id);
			if(record.SmallPhotoUrl) cmp.set('v.thumb', record.SmallPhotoUrl);
			cmp.set('v.isSelected', true);
		}else if(value){
			// Otherwise use value if provided
			// if text empty, use record id as record name (text is already populated by databinding if value exist)
			var text = cmp.get('v.text');
			if(!text){
				cmp.set('v.text', value);
			}
			cmp.set('v.isSelected', true);
		}


		// Check if sobject is user
		var sobject = cmp.get('v.sobject');
        if(sobject && sobject.toLowerCase() === "user"){
			var fields = cmp.get('v.fields');
			if(!fields) fields = [];
			// Always check if not already preset. Looks like aura is initializing twice sometimes
			if(fields.indexOf('SmallPhotoUrl') == -1) fields.push('SmallPhotoUrl');
			if(fields.indexOf('Alias') == -1) fields.push('Alias');
        }

        // Run renderer
		hlp.rerender(cmp);
	},

	recordChangeHandler:function(cmp, evt, hlp) {
		// Update viewmodel if record reference changed externally
		// This method must ommit action if record set by selecting from lookup!
		// As change handler is triggered on reference, newRef and oldRef properties will be the same

		// Get props
		var isSelected = cmp.get('v.isSelected');
		var isInternalSet = cmp.get('v.isInternalSet');
		cmp.set('v.isInternalSet', false); // Reset internal set flag
      	var oldRef = evt.getParam("oldValue");
        var newRef = evt.getParam("value");
      	var oldId = cmp.get("v.prevValue");
      	var currentId = cmp.get("v.value");
    	var initPopulation = !oldRef;
        var key = cmp.get('v.key')||'';
        

		// Skip action
		if(isInternalSet){console.log('cmp:lookup',key,'recordChangeHandler()', 'set-interally'); return;} // reference was set based on user selection from uilookup itself
        if (typeof newRef !== 'object') return; // Change handler will report all property changes on the object. We have to ignore that 
        if (Array.isArray(newRef)) return; // Also ignore case when lookup placed in aura:iteration => lookup may receive whole array instead of record (ligthning nonsense) 
        if(!oldRef && !newRef) return; // prev and new val null => ignore
        if(!isSelected && (!newRef || !newRef.Id)){ // no selection and no value to select provided => ignore
			console.log('cmp:lookup',key,'recordChangeHandler()','nothing-to-select', {old:oldRef, new: newRef});
        	return;
        } 

        // Clear
        if(isSelected && (!newRef || !newRef.Id)){ // currently selected but new value empty => clear
        	console.log('cmp:lookup',key,'recordChangeHandler()','clear', {old:oldRef, new: newRef});
			hlp.clear(cmp, evt, true, true);
			return;
        }

        // Change
        if(newRef && newRef.Id){ // value provided
        	// If new value is the same as as current selection and not init population => ignore
	        if(!initPopulation && newRef.Id === oldId && isSelected){
				console.log('cmp:lookup',key,'recordChangeHandler()','same-value', {old:currentId, new: newRef.Id});
	        	return; 
	        } 

	        // Value is different, set the model
	        cmp.set('v.prevValue', currentId);
			cmp.set('v.value', newRef.Id);
			cmp.set('v.text', newRef.Name || newRef.Id);
			if(newRef.SmallPhotoUrl) cmp.set('v.thumb', newRef.SmallPhotoUrl);	
			cmp.set('v.isSelected', true);
			console.log('cmp:lookup',key,'recordChangeHandler()','set', {old:oldRef, new: newRef});
			return;
        }
	},

	search: function(cmp, evt, hlp) {
		evt.stopPropagation();
		hlp.search(cmp, evt);
	},

	delayedSearch: function(cmp, evt, hlp){
		if(!cmp.get('v.autosearch')) return;

        if(hlp.delayTimer){
        	window.clearTimeout(hlp.delayTimer);
        }

        if(evt.keyCode == 13){
			hlp.search(cmp, evt);
        }
        else{    	
            hlp.delayTimer = window.setTimeout(function(){
				$A.getCallback(function() {
				    if (cmp.isValid()) {
				        hlp.search(cmp, evt);
				    }
				})();
        	}, 400);
        }
    },

	clear : function(cmp, evt, hlp) {
		if(!hlp.isWritable(cmp)) return;
		hlp.clear(cmp, evt);
	},	

	inputClick : function(cmp, evt, hlp) {
		evt.stopPropagation();
	},
	inputFocus : function(cmp, evt, hlp) {
    	var isSelected = cmp.get('v.isSelected');
    	if(isSelected) return;
		evt.stopPropagation();
		cmp.set('v.hasFocus',true);
		hlp.search(cmp, evt);
	},

	optionClick : function(cmp, evt, hlp) {
		hlp.select(cmp, evt, hlp);
	},	
	optionKeyup : function(cmp, evt, hlp) {
		if(evt.keyCode == 13){
    		hlp.closeDropdown(cmp);
		}
	},	
	optionBlur : function(cmp, evt, hlp) {},		
	optionFocus : function(cmp, evt, hlp) {},

	showTooltip : function(cmp, evt, hlp) {
		var pop = evt.target.getElementsByClassName("slds-popover")[0];
		pop.classList.add("slds-rise-from-ground");
		pop.classList.remove("slds-fall-into-ground");
	},		
	hideTooltip : function(cmp, evt, hlp) {
		var pop = evt.target.getElementsByClassName("slds-popover")[0];
		pop.classList.add("slds-fall-into-ground");
		pop.classList.remove("slds-rise-from-ground");
	},					
})