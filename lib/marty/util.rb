module Marty::Util
  def self.set_posting_id(sid)
    snap = Marty::Posting.find_by_id(sid)
    sid = nil if snap && (snap.created_dt == Float::INFINITY)
    Netzke::Base.session[:posting] = sid
  end

  def self.get_posting
    sid = Netzke::Base.session && Netzke::Base.session[:posting]
    return unless sid.is_a? Integer

    sid && Marty::Posting.find_by_id(sid)
  end

  def self.get_posting_time
    snap = get_posting
    snap ? snap.created_dt : Float::INFINITY
  end

  def self.warped?
    get_posting_time != Float::INFINITY
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
    return r if r == 'empty' || r.nil?

    m = pg_range_match(r)

    raise "bad PG range #{r}" unless m

    if m[:start] == ''
      res = ''
    else
      op = m[:open] == '(' ? '>' : '>='
      res = "#{op}#{m[:start]}"
    end

    if m[:end] != ''
      op = m[:close] == ')' ? '<' : '<='
      res += "#{op}#{m[:end]}"
    end

    res
  end

  def self.human_to_pg_range(r)
    return r if r == 'empty'

    m = /\A
    ((?<op0>\>|\>=)(?<start>[^\<\>\=]*?))?
    ((?<op1>\<|\<=)(?<end>[^\<\>\=]*?))?
    \z/x.match(r)

    raise "bad range #{r}" unless m

    if m[:op0]
      open = m[:op0] == '>' ? '(' : '['
      start = "#{open}#{m[:start]}"
    else
      start = '['
    end

    if m[:op1]
      close = m[:op1] == '<' ? ')' : ']'
      ends = "#{m[:end]}#{close}"
    else
      ends = ']'
    end

    "#{start},#{ends}"
  end

  def self.db_in_recovery?
    status = false
    begin
      sql = 'select pg_is_in_recovery();'
      result = ActiveRecord::Base.connection.execute(sql)
      status = result[0]['pg_is_in_recovery'] == 't' if result && result[0]
    rescue StandardError => e
      Marty::Util.logger.error 'unable to determine recovery status'
    end
    status
  end

  def self.deep_round(obj, digits)
    case obj
    when Array
      obj.map { |o| deep_round(o, digits) }
    when Hash
      obj.inject({}) do |result, (key, value)|
        result[key] = deep_round(value, digits)
        result
      end
    else
      obj.is_a?(Float) ? obj.round(digits) : obj
    end
  end

  # Run a report as a promise and return its promise ID.
  def self.background_report(script_name, node_name, params, force)
    engine = Marty::ScriptSet.new.get_engine(script_name)
    res = engine.background_eval(node_name,
                                 params,
                                 ['result', 'title', 'format'],
                                )

    promise_id = res.__promise__.id
    res.force if force

    promise_id
  end

  # generates the report path to report described by script, node, and params
  def self.gen_report_path(script, node, params = {})
    engine = Marty::ScriptSet.new.get_engine(script)
    format = engine.evaluate(node, 'format')
    title  = params.delete(:title) || engine.evaluate(node, 'title')
    data   = ({ selected_script_name: script,
               selected_node: node } + params).to_json
    URI.encode("#{Marty::Util.marty_path}/report?data=#{data}"\
               "&reptitle=#{title}&format=#{format}")
  end

  def self.scrub_obj(obj)
    trav = lambda { |o|
           if o.is_a?(Hash)
             return o.each_with_object({}) { |(k, v), h| h[k] = trav.call(v) }
           elsif o.is_a?(Array)
             return o.map { |v| trav.call(v) }
           elsif o.to_s.length > 10000
             o.class.to_s
           else
             o
           end
    }
    trav.call(obj)
  end
end
