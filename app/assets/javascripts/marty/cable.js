//= require action_cable
//= require_self

(function() {
  this.RailsApp || (this.RailsApp = {});

  this.RailsApp.startActionCable = () => {
    // Already started
    if (RailsApp.cable) {
      return false;
    }

    const protocol =
      window.location.protocol.slice(0, 5) === "https" ? "wss" : "ws";

    if (window.location.port === "") {
      RailsApp.cable = ActionCable.createConsumer(
        `${protocol}://${window.location.hostname}/cable`
      );
    } else {
      RailsApp.cable = ActionCable.createConsumer(
        `${protocol}://${window.location.hostname}:${window.location.port}/cable`
      );
    }

    return true;
  };
}.call(this));
