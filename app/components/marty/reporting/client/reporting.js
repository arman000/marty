({
  selectReport() {
    // this.netzkeGetComponent('report_form').netzkeLoad({});
    // FIXME: NetzkeReload() doesn't work when performed on
    // ReportForm. So, reload all of Reporting.
    this.netzkeReload();
  }
});
