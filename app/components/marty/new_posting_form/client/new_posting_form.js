({
  closeMe() {
    // assume we're embedded in a window
    this.netzkeGetParentComponent().close();
  }
});
