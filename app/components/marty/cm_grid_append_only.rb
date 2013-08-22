class Marty::CmGridAppendOnly < Marty::McflyGridPanel
  def configure(c)
    super

    c.enable_extended_search 	= false
    c.enable_edit_in_form 	= true
    c.prohibit_update 	= true
    c.prohibit_delete 	= true
  end

  def default_bbar
    [:del, :add_in_form]
  end
end
