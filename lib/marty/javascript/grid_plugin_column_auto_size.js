/**
 * @author Maxim Lichmanov
 *
 * {@link http://reanimatter.com}
 *
 * A grid plugin, which sizes the columns to fit the max content width.
 */
Ext.define('Ext.ux.grid.plugin.AutoSizeColumn', function() {
    function onBindStore(store) {
        store.on('clear', onStoreClear, this);
    }

    /**
     * @inheritdoc Ext.view.AbstractView#onUnbindStore
     */
    function onUnbindStore(store) {
        store.un('clear', onStoreClear, this);
    }

    /**
     * @member Ext.ux.grid.plugin.AutoSizeColumn
     *
     * @param {Ext.data.Store} store
     */
    function onStoreClear(store) {
        if (this.isDisabled()) {
            this.enable();
        }
    }

    /**
     * @member Ext.ux.grid.plugin.AutoSizeColumn
     *
     * @param {Ext.grid.View} view The grid view.
     */
    function onViewRefresh(view) {
        var ancestor;

        // There might be a hidden ancestor in the ownership hierarchy.
        // In this case, auto-sizing should be postponed until ancestor is shown.
        if (ancestor = this.getCmp().up('[hidden]')) {
            ancestor.on('show', function() {
                this.autoSizeColumns();
            }, this, {single: true});
            return;
        }

        this.autoSizeColumns();
    }

    return {
        extend: 'Ext.plugin.Abstract',

        alias: 'plugin.autosizecolumn',

        config: {
            /**
             * @cfg {Number} [maxAutoSizeWidth] The maximum auto-sized column width.
             */
            maxAutoSizeWidth: 250
        },

        /**
         * @inheritdoc
         */
        init: function(grid) {
            var view = grid.getView(),
                store = grid.getStore();

            this.setCmp(grid);

            store.on('clear', onStoreClear, this);

            view.onBindStore = Ext.Function.createSequence(view.onBindStore, onBindStore);
            view.onUnbindStore = Ext.Function.createSequence(view.onUnbindStore, onUnbindStore);

            this.enable();
        },

        /**
         * Sizes visible columns to fit the max content width.
         */
        autoSizeColumns: function() {
            var grid = this.getCmp(),
                view = grid.getView(),
                // HACK: not sure why Ext.state.Stateful#getStateId is private 'cause it seems to be valid to be public.
                id = grid.stateful && grid.getStateId(),
                maxAutoSizeWidth = this.getMaxAutoSizeWidth();

            // If grid is stateful and state is saved in a storage,
            // column widths are applied from the state (unless the auto-sizing is enforced).
            if (id && Ext.state.Manager.get(id)) {
                this.disable();
            }

            if (this.isDisabled() || !grid.getStore().getCount()) {
                return;
            }

            grid.suspendLayouts();

            Ext.each(grid.getVisibleColumns(), function(column) {
                var maxContentWidth;

                // Flexible columns should not be affected.
                if (column.flex) {
                    return;
                }

                // HACK: using private method Ext.view.View#getMaxContentWidth
                maxContentWidth = view.getMaxContentWidth(column);

                if (maxAutoSizeWidth > 0 && maxContentWidth > maxAutoSizeWidth) {
                    column.setWidth(maxAutoSizeWidth);
                }
                else {
                    column.autoSize();
                }
            });

            grid.resumeLayouts();

            this.disable();

            grid.updateLayout();
        },

        /**
         * Returns true, if plugin is disabled, false otherwise.
         *
         * @return {Boolean}
         */
        isDisabled: function() {
            return this.disabled;
        },

        /**
         * @inheritdoc
         */
        disable: function() {
            this.callParent();
            this.getCmp().getView().un('refresh', onViewRefresh, this);
        },

        /**
         * @inheritdoc
         */
        enable: function() {
            this.callParent();

            this.getCmp().getView().on('refresh', onViewRefresh, this);
        },

        /**
         * @inheritdoc
         */
        destroy: function() {

        }
    };
});
