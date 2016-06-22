require 'marty/new_posting_form'

class Marty::NewPostingWindow < Netzke::Window::Base
  def configure(c)
    super

    c.title             = I18n.t('new_posting')
    c.modal             = true
    c.items             = [:new_posting_form]
    c.lazy_loading      = true
  end

  component :new_posting_form do |c|
    c.header = false
  end

end

NewPostingWindow = Marty::NewPostingWindow
