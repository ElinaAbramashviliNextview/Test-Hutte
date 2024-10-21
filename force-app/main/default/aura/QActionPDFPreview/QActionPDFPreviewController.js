({
	init: function (cmp, evt, hlp) {
		cmp.set('v.isLoading', false);
		cmp.set('v.isReady', true);
		hlp.check(cmp);
        hlp.templateProductCheck(cmp);
	},

	backBtn: function(cmp, evt, hlp){
		hlp.redirectToQT(cmp);
	},

	savePdf: function(cmp, evt, hlp){
		hlp.save(cmp);
	}
})