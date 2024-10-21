({
	init : function(cmp, evt, hlp) {
		// Generate id if not provided
		var id = cmp.get('v.id');
		if(!id){cmp.set('v.id', 'G' + (new Date()).getTime() + 'X' + Math.random().toString(36).substr(2, 9));}
	},

	open : function(cmp, evt, hlp) {
        /* With scrolls hidden */
        //cmp.set("v.cssStyle", "body{overflow:hidden!important;} .forceStyle .viewport .oneHeader.slds-global-header_container {z-index:0!important} .forceStyle.desktop .viewport{overflow:hidden}");
        /* With scrolls left intact - prevents jumping is scrolled down before modal opened */
        cmp.set("v.cssStyle", "body{} .forceStyle .viewport .oneHeader.slds-global-header_container {z-index:0!important} .forceStyle.desktop .viewport{}");
		cmp.set('v.isOpen', true);
		var id = cmp.get('v.id');
		setTimeout(function(){
			var el = document.getElementById(id);
			el.focus();
		},200);	
	},

    closeOnEsc: function(cmp, evt, hlp) {
		if (cmp.get('v.closeOnEsc') && evt.keyCode === 27) {
			hlp.close(cmp);
		}
    },
    close: function(cmp, evt, hlp) {
        var params = evt.getParam('arguments');
        var skipOnClose = false;        
        if (params) {
            skipOnClose = params.skipOnClose;
        }    	
    	var closeCallback = cmp.get('v.fnOnClose');
		hlp.close(cmp);
    	if(closeCallback && !skipOnClose) closeCallback();
    },

    showLoader: function(cmp, evt, hlp) {
		cmp.set('v.isLoading', true);
    },

    hideLoader: function(cmp, evt, hlp) {
		cmp.set('v.isLoading', false);
    }      
});