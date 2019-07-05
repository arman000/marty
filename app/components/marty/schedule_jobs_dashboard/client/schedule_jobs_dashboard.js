{
    netzkeReschedule: function(params) {
	var me = this;
	Ext.Msg.confirm(
            'Reschedule Jobs',
            Ext.String.format('Are you sure?'),
            function (btn, value, cfg) {
		if (btn == "yes") {
		    me.server.reschedule();
		}
            });
    }
}
