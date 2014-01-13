module Marty::Util
  def self.set_posting_id(sid)
    snap = Marty::Posting.find_by_id(sid)
    sid = nil if snap && (snap.created_dt == Float::INFINITY)
    Netzke::Base.session[:posting] = sid
  end

  def self.get_posting
    sid = Netzke::Base.session && Netzke::Base.session[:posting]
    return unless sid.is_a? Fixnum
    sid && Marty::Posting.find_by_id(sid)
  end

  def self.get_posting_time
    snap = self.get_posting
    snap ? snap.created_dt : Float::INFINITY
  end

  def self.warped?
    self.get_posting_time != Float::INFINITY
  end

  def self.logger
    @@s_logger ||= Rails.logger || Logger.new($stderr)
  end

  # route path to where Marty is mounted
  def self.marty_path
    Rails.application.routes.named_routes[:marty].path.spec
  end
end
