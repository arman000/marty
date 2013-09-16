class Marty::NewPostingForm < Marty::CmFormPanel
  has_marty_permissions	create: :price_manager,
			read: :any,
			update: :price_manager,
			delete: :none

  js_configure do |c|
    c.close_me = <<-JS
    	function() {
	  // assume we're embedded in a window
	  this.netzkeGetParentComponent().close();
    	}
    JS
  end

  action :apply do |a|
    a.text  	= I18n.t("create_posting")
    a.tooltip  	= I18n.t("create_posting")
    a.icon  	= :time_add
    a.disabled 	= Marty::Util.warped? || !self.class.can_perform_action?(:create)
  end

  ######################################################################
    
  endpoint :netzke_submit do |params, this|
    unless self.class.can_perform_action?(:create)
      this.netzke_feedback "Permission Denied"
      return
    end

    res = super(params, this)
    this.close_me
    res
  end

  def configure(c)
    super

    c.model = "Marty::Posting"
    c.items = [
               :posting_type__name,
               :is_test,
               :comment,
              ]
  end

end

NewPostingForm = Marty::NewPostingForm
