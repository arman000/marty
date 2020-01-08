({
  netzkeOnForeground() {
    const values = this.getForm().getValues();
    const data = Ext.encode(values);

    const params = {
      data,
      reptitle: this.reptitle
    };

    // very hacky -- when selected_testing is set, we assume we're
    // testing and try to inline the result.
    if (values["selected_testing"]) {
      this.repformat = "txt";
      params["disposition"] = "inline";
    }

    const form = document.createElement("form");

    form.setAttribute("method", "post");
    form.setAttribute("action", this.mountPath() + "/report." + this.repformat);

    // set authenticity token
    const hiddenField = document.createElement("input");
    hiddenField.setAttribute("type", "hidden");
    hiddenField.setAttribute("name", "authenticity_token");
    hiddenField.setAttribute("value", this.authenticityToken);
    form.appendChild(hiddenField);

    for (const key in params) {
      if (Object.prototype.hasOwnProperty.call(params, key)) {
        const hiddenField = document.createElement("input");
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

  netzkeOnLink() {
    const values = this.getForm().getValues();

    // check for early url generation and exit with error message
    if (values["selected_script_name"] == null) {
      alert("Please select a report before generating url.");
      return;
    }

    const params = {
      format: this.repformat,
      reptitle: this.reptitle
    };

    let key;

    for (key in values) {
      if (values[key] == "") {
        delete values[key];
      }
    }
    const data = Ext.encode(values);

    // construct url
    const proto_host = location.protocol + "//" + location.host;
    let url = proto_host + "/report?data=" + data;
    for (key in params) {
      if (params[key] == "") continue;
      url += "&" + key + "=" + params[key];
    }
    url = encodeURI(url);
    const win = window.open("");
    win.document.write(url.link(url));
  }
});
