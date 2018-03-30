{
    // copied from basepack grid's onEditInForm
    netzkeOnDupInForm: function(){
        var selModel = this.getSelectionModel();
        var recordId = selModel.getSelection()[0].getId();
        this.netzkeLoadComponent("edit_window", {
            title: "Duplicate in Form",
            serverConfig: {record_id: recordId},
            callback: function(w){
                w.show();
                var form = w.items.first();
                form.baseParams = {dup: true};
                w.on('close', function(){
                    if (w.closeRes === "ok") {
                        this.store.load();
                    }
                }, this);
            }, scope: this});
    }
}
