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

    const dgNameField = fields.find((field) => {
      return field.name === "data_grid_name";
    });

    const postingField = fields.find((field) => {
      return field.name === "pt_name";
    });

    const newValue = dgNameField.getValue();

    if (!newValue) {
      return;
    }

    if (this.previousDataGridValue === newValue) {
      return;
    }

    const ptName = postingField.getValue();

    this.server.updateDataGridJsonField(
      { pt_name: ptName, data_grid_name: newValue },
      (response) => {
        const fields = this.getForm().getFields();

        const parametersField = fields.find((field) => {
          return field.name === "parameters_json";
        });

        parametersField.setValue(response);
      }
    );
  }
});
