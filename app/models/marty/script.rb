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

  delorean_fn :eval_to_hash, sig: 5 do
    |dt, script, node, attrs, params|
    tag = Marty::Tag.find_match(dt)

    # IMPORTANT: engine evals (e.g. eval_to_hash) modify the
    # params. So, need to clone it.
    params = params.clone

    raise "no tag found for #{dt}" unless tag

    engine = Marty::ScriptSet.new(tag).get_engine(script)
    res = engine.eval_to_hash(node, attrs, params)

    # FIXME: should sanitize res to make sure that no nodes are being
    # passed back.  It's likely that nodes which are not from the
    # current tag can caused problems.
    res
  end
end
