({
    netzkeOnDiff(_params) {
        const me = this;
        const records = me.getSelection().map(function (r) {
            return r.data;
        });
        me.server.diff(records, function () {
            me.unmask();
        });
    },

    netzkeOnDownload(_params) {
        const me = this;
        const records = me.getSelection().map(function (r) {
            return r.data;
        });
        me.server.download(records, function () {
            me.unmask();
        });
    },

    downloadReport(report_path) {
        window.location = report_path;
    },
});
