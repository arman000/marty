class Marty::Form < Netzke::Form::Base
  extend ::Marty::Permissions

  client_class do |c|
    c.include :form
  end

  def initialize(args, kwargs = nil)
    super(args, kwargs)

    # That's a hacky way to modify behaviour on form submit without need to
    # override the endpoints in parent component
    define_singleton_method :create_or_update_record, config.submit_handler if config.submit_handler
  end
end
