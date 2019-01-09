{
    netzkeOnForeground: function () {
    var values = this.getForm().getValues();
    var data = Ext.encode(values);

    var params = {
      data: data,
      reptitle: this.reptitle
    };

    // very hacky -- when selected_testing is set, we assume we're
    // testing and try to inline the result.
    if (values["selected_testing"]) {
      this.repformat = "txt";
      params["disposition"] = "inline";
    }

    var form = document.createElement("form");

    form.setAttribute("method", "post");
    form.setAttribute("action", this.mountPath() + "/report." + this.repformat);

    // set authenticity token
    var hiddenField = document.createElement("input");
    hiddenField.setAttribute("type", "hidden");
    hiddenField.setAttribute("name", "authenticity_token");
    hiddenField.setAttribute("value", this.authenticityToken);
    form.appendChild(hiddenField);

    for (var key in params) {
      if (params.hasOwnProperty(key)) {
        var hiddenField = document.createElement("input");
        hiddenField.setAttribute("type", "hidden");
        hiddenField.setAttribute("name", key);
        hiddenField.setAttribute("value", params[key]);

        form.appendChild(hiddenField);
      }
    }

    document.body.appendChild(form);
    form.submit();
    document.body.removeChild(form);
  },

  netzkeOnLink: function () {
    var values = this.getForm().getValues();

    // check for early url generation and exit with error message
    if (values['selected_script_name'] == null) {
      alert("Please select a report before generating url.");
      return;
    }

    params = {
      "format": this.repformat,
      "reptitle": this.reptitle
    }

    for (var key in values) {
      if (values[key] == "") {
        delete values[key]
      }
    }
    data = Ext.encode(values)

    // construct url
    var proto_host = location.protocol + '//' + location.host
    var url = proto_host + '/report?data=' + data
    for (var key in params) {
      if (params[key] == "") continue;
      url += '&' + key + '=' + params[key];
    }
    url = encodeURI(url)
    var win = window.open('');
    win.document.write(url.link(url));
  }
}
