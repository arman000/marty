({
  initComponent() {
    this.callParent();
    this.getView().getRowClass = this.getRowClass;
  },
  getRowClass(row) {
    const { message_type: messageType } = row.data;
    let typeClass;

    switch (messageType) {
      case "info":
        typeClass = "cyan";
        break;
      case "warn":
        typeClass = "yellow";
        break;
      case "error":
        typeClass = "red";
        break;
      case "fatal":
        typeClass = "charcoal";
        break;
      default:
        return "default";
    }

    return `bg-pennymac-${typeClass}`;
  }
});
