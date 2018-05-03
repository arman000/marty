class Marty::RecordFormWindow < Netzke::Basepack::RecordFormWindow
  def configure(c)
    super c
    c.fbar = [] if c.item_id == 'view_window'
  end

  component :view_form do |c|
    preconfigure_form(c)
    c.record_id = config.client_config[:record_id]
    c.mode = :lockable
  end
end
