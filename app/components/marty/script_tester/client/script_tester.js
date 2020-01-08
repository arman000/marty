({
  setResult(val) {
    const result = this.netzkeGetComponent("result");
    result.updateBodyHtml(val);
  }
});
