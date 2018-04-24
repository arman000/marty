class Marty::GridAppendOnly < Marty::McflyGridPanel
  def configure(c)
    super
    c.permissions[:update]   = false
  end
end
