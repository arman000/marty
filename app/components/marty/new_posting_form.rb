class Marty::NewPostingForm < Marty::Form
  extend ::Marty::Permissions

  # override this to set permissions for posting types
  has_marty_permissions read: :any

  client_class do |c|
    c.close_me = l(<<-JS)
    function() {
      // assume we're embedded in a window
      this.netzkeGetParentComponent().close();
    }
    JS
  end

  action :apply do |a|
    a.text    = I18n.t("create_posting")
    a.tooltip = I18n.t("create_posting")
    a.icon    = :time_add
  end

  ######################################################################

  endpoint :submit do |params|
    res = super(params)
    client.close_me
    res
  end

  def configure(c)
    super

    c.model = "Marty::Posting"
    c.items = [
               {
                 name: :posting_type__name,
                 scope: lambda { |r|
                   r.where(name: Marty::NewPostingForm.can_perform_actions)
                 },
               },
               :comment,
              ]
  end
end

NewPostingForm = Marty::NewPostingForm
