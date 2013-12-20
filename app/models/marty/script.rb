require 'mcfly'

# FIXME: modification of Script should be disallowed unless it's
# through checkin.

class Marty::Script < Marty::Base
  has_mcfly

  attr_accessible :name, :body, :version, :logmsg
  validates_presence_of :name, :body, :version, :logmsg, :user
  mcfly_validates_uniqueness_of :name
  validates_format_of :name, {
    with: /\A[A-Z][a-zA-Z0-9]*\z/,
    message: I18n.t('script.save_error'),
  }

  belongs_to :user, class_name: "Marty::User"
  has_one :dscript

  DEV_VERSION = "DEV"
  SAMPLE_SCRIPT = <<eof
# your script goes here ...
BaseProgram:
	loan_program_name = 'BaseProgram'
	division_name =? 'CLG'
	lock_type_name =?	# e.g. 'Best Efforts'
	note_rate =? 3.25
	market_price = 105.0156250
	gfee = 0.31
	base_servicing_rate = 0.25
DerivedProgram: BaseProgram
	some_calc = gfee + base_servicing_rate + note_rate
eof

  def self.create_script(name)
    # Creates the initial place-holder script object and check it
    # out.
    script 		= new
    script.name 	= name
    script.version 	= DEV_VERSION
    script.body 	= SAMPLE_SCRIPT
    script.logmsg 	= DEV_VERSION

    if script.valid?
      script.save
      script.checkout
    end

    script
  end

  # check out script as user
  def checkout
    raise "already checked out" if dscript

    # obsoleted_dt is nil if it's newly created
    raise "can only check out current version" unless
      (obsoleted_dt.nil? || obsoleted_dt == Float::INFINITY)

    ds 		= Marty::Dscript.new
    ds.script	= self
    ds.body 	= body
    ds.user 	= Mcfly.whodunnit
    ds.save!
  end

  def last_version
    Marty::Script.find(group_id)
  end

  def isdev?
    version == DEV_VERSION
  end

  def istip?
    obsoleted_dt == Float::INFINITY
  end

  def group_dscript
    last_version.dscript
  end

  def differs_from_dscript?
    ds = group_dscript
    ds && (body != ds.body)
  end

  def dev_version
    Marty::Script.where("group_id = ? AND version = ?",
                        group_id, DEV_VERSION).first
  end

  # FIXME: If we allow scripts to be deleted, then this method needs
  # to be fixed.  It's possible that a script with some versions is
  # deleted.  Then if a new script of same name is created, a
  # reference to name/version becomes ambiguous.  The best solution
  # is to start new version numbers on the new script from where we
  # left off.
  def self.find_script(sname, version)
    q = version ? where("name = ? AND version = ?", sname, version) :
      # no version provided, so we pick the tip
      where("name = ? AND id = group_id", sname)

    # order by obsoleted_dt so we get the latest version.  Of
    # course, we may still hit scripts which are already obsoleted.
    q.order('obsoleted_dt DESC').first
  end

  gen_mcfly_lookup :get_all, {}, mode: :all
end
