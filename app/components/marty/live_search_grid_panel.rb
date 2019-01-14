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
  client_class do |c|
    c.include :live_search_grid_panel
  end

  def get_records(params)
    search_scope = config[:live_search_scope] || :live_search
    model.send(search_scope, params && params[:live_search] || '').scoping do
      super
    end
  end
end
