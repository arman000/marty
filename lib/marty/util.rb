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

  def self.pg_range_match(r)
    /\A(?<open>\[|\()(?<start>.*?),(?<end>.*?)(?<close>\]|\))\z/.match(r)
  end

  def self.pg_range_to_human(r)
    return r if r == "empty" || r.nil?

    m = pg_range_match(r)

    raise "bad PG range #{r}" unless m

    if m[:start] == ""
      res = ""
    else
      op = m[:open] == "(" ? ">" : ">="
      res = "#{op}#{m[:start]}"
    end

    if m[:end] != ""
      op = m[:close] == ")" ? "<" : "<="
      res += "#{op}#{m[:end]}"
    end

    res
  end

  def self.human_to_pg_range(r)
    return r if r == "empty"

    m = /\A
    ((?<op0>\>|\>=)(?<start>[^\<\>\=]*?))?
    ((?<op1>\<|\<=)(?<end>[^\<\>\=]*?))?
    \z/x.match(r)

    raise "bad range #{r}" unless m

    if m[:op0]
      open = m[:op0] == ">" ? "(" : "["
      start = "#{open}#{m[:start]}"
    else
      start = "["
    end

    if m[:op1]
      close = m[:op1] == "<" ? ")" : "]"
      ends = "#{m[:end]}#{close}"
    else
      ends = "]"
    end

    "#{start},#{ends}"
  end
end
