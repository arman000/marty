class Marty::Dscript < Marty::Base
  attr_accessible :script_id, :body
  validates_uniqueness_of :script_id
  validates_presence_of :script_id, :body, :user

  belongs_to :user, class_name: "Marty::User"
  belongs_to :script, class_name: "Marty::Script"

  def checkin(msg)
    if body != script.body
      # If the body has changed, create a new version. NOTE: this is
      # a bit of a hack to 0 pad the version.  It's done so that the
      # versions still sort properly when version > 9.
      script.version = "%04d" % (script.isdev? ? 1 :
                                 script.version.to_i + 1)
      script.logmsg = msg
      script.body = self.body
      script.save!
    end
    self.delete
  end

  def discard
    # also delete associated script if this it's a DEV record
    self.script.delete if
      self.script.isdev? && self.script.istip?

    self.delete
  end
end
