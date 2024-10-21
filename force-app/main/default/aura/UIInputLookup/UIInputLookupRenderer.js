({
	rerender: function(cmp, hlp) {
	 	this.superRerender();
	 	hlp.rerender(cmp);
	},
	afterRender: function(cmp, hlp) {
	 	this.superAfterRender();
	 	hlp.rerender(cmp);
	 	
		// Show tooltip if provided
		var tt = hlp.cTooltip(cmp);
		if(cmp.get('v.tooltip')){
	        $A.util.removeClass(tt, 'slds-hide');
	        $A.util.addClass(tt, 'slds-align-middle');
		}
	},
 })