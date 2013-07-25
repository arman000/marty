require 'marty/new_posting_form'

class Marty::NewPostingWindow < Netzke::Basepack::Window
  def configure(c)
    super

    c.title 		= I18n.t('new_posting')
    c.modal 		= true
    c.items 		= [:new_posting_form]
    c.lazy_loading 	= true
    c.width 		= 350
    c.height 		= 150
  end

  component :new_posting_form do |c|
    c.header = false
  end

end

NewPostingWindow = Marty::NewPostingWindow
