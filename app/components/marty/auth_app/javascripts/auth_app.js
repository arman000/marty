{
    onSignIn: function() {
	var me = this;
	this.signinWin = this.signinWin || Ext.create('Ext.Window', {
	    width: 	300,
	    height: 	150,
	    modal: 	true,
	    layout: 	'fit',

	    submit: function() {
		var form 	= this.items.first();
		var values 	= form.getForm().getValues();

		// calling the endpoint
		me.signIn(values, function(res) {
		    if (res) {
			this.signinWin.close();
			Ext.Msg.show({
			    title: 	"Signed in",
			    msg: 	"Signed in successfully, reloading...",
			    icon: 	Ext.Msg.INFO,
			    closable: 	false
			});
			window.location.href = "/";
		    }
		});
	    },

	    closeAction: 'hide',
	    title: "Sign in",
	    fbar: [
		{
		    text: 'OK',
		    name: 'signin_submit',
		    handler: function() {
			this.up('window').submit();
		    },
		},
		{
		    text:'Cancel',
		    handler: function() {
			this.up('window').close();
		    },
		},
	    ],

	    items: {
		xtype: 		'form',
		defaultType: 	'textfield',
		bodyPadding: 	'15px 0px 0px 10px',
		defaults: {
		    listeners: {
			specialkey: function (field, event) {
			    if (event.getKey() == event.ENTER) {
				field.up('window').submit();
			    }
			}
		    },
		},
		items: [
		    {
			fieldLabel: 	'Login',
			name: 		'login',
		    },
		    {
			fieldLabel: 	'Password',
			name: 		'password',
			inputType: 	'password',
		    }
		]
	    }
	});

	this.signinWin.show();
	this.signinWin.down('textfield').focus(false, 100);
    },

    onSignOut: function() {
	this.signOut(null, function(success) {
	    if (success) {
		Ext.Msg.show({
		    title: 	"Signed out",
		    msg: 	"Signed out, reloading the application...",
		    icon: 	Ext.Msg.INFO,
		    closable: 	false
		});
		window.location.href = "/";
	    }
	})
    }
}
