({
  createPopupWindow(htmlToShow, titleToShow, heightToUse, widthToUse) {
    Ext.create("Ext.Window", {
      height: heightToUse,
      minWidth: widthToUse,
      autoWidth: true,
      layout: "fit",
      modal: false,
      autoScroll: true,
      html: htmlToShow,
      title: titleToShow
    }).show();
  }
});
