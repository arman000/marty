class Marty::GridAppendOnly < Marty::McflyGridPanel
  def configure(c)
    super

    c.paging                 = :pagination
    c.editing                = :in_form
    c.permissions[:update]   = false
  end

end
