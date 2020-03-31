({
  initComponent() {
    this.viewConfig = {
      getRowClass(r) {
        return r.get("klass") === "Total" ? "bold" : "";
      }
    };
    this.callParent();
  }
});
