require 'mcfly'

class Marty::Script < Marty::Base
  has_mcfly

  attr_accessible :name, :body
  validates_presence_of :name, :body
  mcfly_validates_uniqueness_of :name
  validates_format_of :name, {
    with: /\A[A-Z][a-zA-Z0-9]*\z/,
    message: I18n.t('script.save_error'),
  }

  belongs_to :user, class_name: "Marty::User"

  def self.find_script(sname, version)
    raise "FIXME: IMPLEMENT"
  end

  gen_mcfly_lookup :get_all, {}, mode: :all
end
