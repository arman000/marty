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

  gen_mcfly_lookup :lookup, {
    name: false,
  }

  gen_mcfly_lookup :get_all, {}, mode: :all

  # find script by name/tag
  def self.find_script(sname, tag=nil)
    tag = Marty::Tag.map_to_tag(tag)
    Marty::Script.lookup(tag.created_dt, sname)
  end

  def find_tag
    # find the first tag created after this script.
    Marty::Tag.where("created_dt >= ?", created_dt).order(:created_dt).first
  end

  def self.create_script(name, body)
    script      = new
    script.name = name
    script.body = body
    script.save
    script
  end
end
