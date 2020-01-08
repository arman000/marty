({
  netzkeOnSignIn() {
    const me = this;
    this.signinWin =
      this.signinWin ||
      Ext.create("Ext.Window", {
        modal: true,
        layout: "fit",

        submit() {
          const form = this.items.first();
          const values = form.getForm().getValues();

          // calling the endpoint
          me.server.signIn(values, function(res) {
            if (res) {
              if (!me.authSpecMode) {
                this.signinWin.close();
              }
              Ext.Msg.show({
                title: "Signed in",
                msg: "Signed in successfully, reloading...",
                icon: Ext.Msg.INFO,
                closable: false
              });
              if (!me.authSpecMode) {
                window.location.href = "/";
              }
            }
          });
        },

        closeAction: "hide",
        title: "Sign in",
        fbar: [
          {
            text: "OK",
            name: "signin_submit",
            handler() {
              this.up("window").submit();
            }
          },
          {
            text: "Cancel",
            handler() {
              this.up("window").close();
            }
          }
        ],

        items: {
          xtype: "form",
          defaultType: "textfield",
          bodyPadding: "15px 15px 0px 10px",
          defaults: {
            listeners: {
              specialkey(field, event) {
                if (event.getKey() == event.ENTER) {
                  field.up("window").submit();
                }
              }
            }
          },
          items: [
            {
              fieldLabel: "Login",
              name: "login"
            },
            {
              fieldLabel: "Password",
              name: "password",
              inputType: "password"
            }
          ]
        }
      });

    this.signinWin.show();
    this.signinWin.down("textfield").focus(false, 100);
  },

  netzkeOnSignOut() {
    this.server.signOut(null, function(success) {
      if (success) {
        Ext.Msg.show({
          title: "Signed out",
          msg: "Signed out, reloading the application...",
          icon: Ext.Msg.INFO,
          closable: false
        });
        window.location.href = "/";
      }
    });
  },

  netzkeOnToggleDarkMode() {
    this.server.toggleDarkMode(() => {
      window.location.href = "/";
    });
  },

  netzkeOnNotificationsWindow() {
    this.netzkeLoadComponent("notifications_window", {
      callback(w) {
        w.show();

        this.server.markWebNotificationsDelivered();

        const notificationsButton = this.menuBar.items.items.find(function(
          item
        ) {
          return item.name === "notificationsWindow";
        });

        notificationsButton.setText(""); // Remove the counter
      }
    });
  },

  netzkeInitComponentCallback() {
    try {
      const subscription = RailsApp.cable.subscriptions.subscriptions.find(
        (sub) => sub.identifier === '{"channel":"Marty::NotificationChannel"}'
      );

      // In case if component is initialized twice
      if (subscription) {
        return;
      }

      RailsApp.cable.subscriptions.create("Marty::NotificationChannel", {
        received: (data) => {
          const notificationsButton = this.menuBar.items.items.find(function(
            item
          ) {
            return item.name === "notificationsWindow";
          });

          if (data.unread_notifications_count > 0) {
            notificationsButton.setText(
              `<span class='notification-counter'>${data.unread_notifications_count}</span>`
            );
          } else {
            notificationsButton.setText("");
          }
        }
      });
    } catch (error) {
      console.log("ActionCable connection failed");
      console.error(error);
    }
  }
});
