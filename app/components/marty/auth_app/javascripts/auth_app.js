{
    onSignIn: function() {
	var me = this;
	this.signinWin = this.signinWin || Ext.create('widget.window', {
	    width: 300, height: 150, modal: true, layout: 'fit',
	    closeAction: 'hide',
	    title: "Sign in",
	    fbar: [
		{text: 'OK', handler: function() {
		    var form = this.up('window').items.first(),
		    values = form.getForm().getValues();

		    // calling the endpoint
		    me.signIn(values, function(res){
			if (res) {
			    this.signinWin.close();
			    Ext.Msg.show({
				title: "Signed in",
				msg: "Signed in successfully, reloading...",
				icon: Ext.Msg.INFO,
				closable: false
			    });
			    window.location = window.location;
			}
		    });
		}},
		{text:'Cancel', handler: function() {
		    this.up('window').close();
		}}
	    ],

	    items: {
		xtype: 'form', bodyPadding: 10,
		defaultType: 'textfield',
		items: [
		    {
			xtype: 'displayfield'
		    },{
			fieldLabel: 'Login',
			name: 'login',
		    },{
			fieldLabel: 'Password',
			name: 'password',
			inputType: 'password',
		    }
		]
	    }
	});

	this.signinWin.show();
    },

    onSignOut: function() {
	this.signOut(null, function(success) {
	    if (success) {
		Ext.Msg.show({
		    title: "Signed out",
		    msg: "Signed out, reloading the application...",
		    icon: Ext.Msg.INFO,
		    closable: false
		});
		window.location = window.location;
	    }
	})
    }
}