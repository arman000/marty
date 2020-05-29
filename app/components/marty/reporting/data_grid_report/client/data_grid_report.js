({
  initComponent() {
    this.callParent();

    const formObject = this.getForm();
    const fields = formObject && formObject.getFields();

    if (!fields) {
      return;
    }

    fields.each((field) => {
      if (field.name !== "data_grid_name") {
        return;
      }
      if (field.hasOnSelectCallBack) {
        return;
      }

      field.on("select", () => {
        this.preloadGridDefaults();
      });
    });
  },

  preloadGridDefaults() {
    const fields = this.getForm().getFields();

    const dg_name_field = fields.find((field) => {
      return field.name === "data_grid_name";
    });

    const postingField = fields.find((field) => {
      return field.name === "pt_name";
    });

    const newValue = dg_name_field.getValue();

    if (!newValue) {
      return;
    }

    if (this.previousDataGridValue === newValue) {
      return;
    }

    const pt_name = postingField.getValue();

    this.server.updateDataGridJsonField(
      { pt_name, data_grid_name: newValue },
      (response) => {
        const fields = this.getForm().getFields();

        const parameters_field = fields.find((field) => {
          return field.name === "parameters_json";
        });

        parameters_field.setValue(response);
      }
    );
  }
});
