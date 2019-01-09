{
  findComponent: function (name) {
    return Ext.ComponentQuery.query(`[name=${name}]`)[0];
  }
}
