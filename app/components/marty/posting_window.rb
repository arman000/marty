class Marty::PostingWindow < Netzke::Basepack::Window
  def configure(c)
    super

    c.title 		= I18n.t('select_posting')
    c.modal 		= true
    c.items 		= [:posting_grid]
    c.lazy_loading 	= true
    c.width 		= 400
    c.height 		= 350
  end

  component :posting_grid do |c|
    c.klass			= Marty::PostingGrid
    c.enable_edit_in_form	= false
    c.enable_extended_search	= false
    c.rows_per_page		= 12
    c.column_filters_available 	= true
    c.prohibit_update		= true
    c.prohibit_delete		= false # hijacked for selection
    c.prohibit_create		= true
    # c.bbar	= []
  end

end

PostingWindow = Marty::PostingWindow
