class Marty::CmGridAppendOnly < Marty::McflyGridPanel
  def configure(c)
    super

    c.enable_extended_search	= false
    c.prohibit_update		= true
  end

  def default_bbar
    [:del, :add_in_form]
  end
end
