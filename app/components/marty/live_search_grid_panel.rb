# The LiveSearchGridPanel provides a search field in the toolbar of
# the GridPanel. While the content of the search field is changeing,
# the data in the grid gets reloaded and the filter string is given to
# a scope on the configured model. The scope name by default is
# :live_search but it can be reconfigured by the configuration option
# :live_search_scope.  NOTE: this is rewrite of the Netzke community
# pack component of the same name.  We should submit this to the
# community.
#
# Options:
# * +live_search_scope+ - The scope name for filtering the results by 
#   the live search (default: :live_search) 
#

class Marty::LiveSearchGridPanel < Marty::McflyGridPanel
  js_configure do |c|
    c.listen_fn = <<-JS
    function(obj, search_text) {
        var lg = this.ownerCt.ownerCt;
    	lg.getStore().getProxy().extraParams.live_search = search_text;
    	lg.getStore().load();
    }
    JS

    c.tbar = ['->', {
                name:  'live_search_text',
                xtype: 'textfield',
                enable_key_events: true,
                ref: '../live_search_field',
                empty_text: 'Search',
                listeners: {
                  change: {
                    fn: c.listen_fn,
                    buffer: 100,
                  }
                }
              }]
  end

  def get_data(*args)
    params = args.first
    search_scope = config[:live_search_scope] || :live_search
    data_class.send(search_scope, params && params[:live_search] || '').scoping do
      super
    end
  end

end

