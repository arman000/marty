//= require action_cable
//= require_self

(function() {
  this.RailsApp || (this.RailsApp = {});

  if (window.location.port === "") {
    RailsApp.cable = ActionCable.createConsumer(`ws://${window.location.hostname}/cable`);
  } else {
    RailsApp.cable = ActionCable.createConsumer(`ws://${window.location.hostname}:${window.location.port}/cable`);
  }
}).call(this);
