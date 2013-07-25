class Marty::NewPostingForm < Marty::CmFormPanel
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
    a.disabled 	= false
  end

  ######################################################################
    
  endpoint :netzke_submit do |params, this|
    unless self.class.has_price_manager_perm?
      this.netzke_feedback "no permission"
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
