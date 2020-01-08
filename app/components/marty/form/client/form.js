({
  findComponent(name) {
    return Ext.ComponentQuery.query(`[name=${name}]`)[0];
  }
});
