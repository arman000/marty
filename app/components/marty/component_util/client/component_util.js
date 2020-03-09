({
  createPopupWindow(html_to_show, title_to_show, height_to_use, width_to_use) {
    Ext.create("Ext.Window", {
      height: height_to_use,
      minWidth: width_to_use,
      autoWidth: true,
      layout: "fit",
      modal: false,
      autoScroll: true,
      html: html_to_show,
      title: title_to_show
    }).show();
  }
});
