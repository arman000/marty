# Netzke Form with Marty permissions
class Marty::Form < Netzke::Form::Base
  extend ::Marty::Permissions

  client_styles do |c|
    c.require :form
  end

  def add_cls_to_fields items
    items.map{|i| i + {'label_cls' => 'marty-form-field-label'}}
  end
end
