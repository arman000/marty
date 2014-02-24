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
  def self.find_script(sname, tag)
    if tag.is_a? String
      tag = Marty::Tag.find_by_name(tag)
    elsif tag.is_a?(Fixnum)
      tag = Marty::Tag.find_by_id(tag)
    end

    raise "no such tag" unless tag

    Marty::Script.lookup(tag.created_dt, sname)
  end
end
