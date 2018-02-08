require 'parse-cron'

class Marty::Delayed::ExtendedCronParser < CronParser
  # inherit CronParser and extend parser to support seconds

  class ExtendedInternalTime < InternalTime
    attr_accessor :year, :month, :day, :hour, :min, :sec
    attr_accessor :time_source

    def initialize(time, time_source = Time)
      super(time, time_source)
      @sec = time.sec
    end

    def to_time
      super + @sec
    end

    def inspect
      [year, month, day, hour, min, sec].inspect
    end
  end

  def validate_source
    unless @source.respond_to?(:split)
      raise ArgumentError, 'not a valid extended cronline'
    end
    source_length = @source.split(/\s+/).length
    unless source_length >= 6 && source_length <= 7
      raise ArgumentError, 'not a valid extended cronline'
    end
  end

  def time_specs
    @time_specs ||=
      begin
        tokens = substitute_parse_symbols(@source).split(/\s+/)
        {
          :second => parse_element(tokens[0], 0..59),
          :minute => parse_element(tokens[1], 0..59),
          :hour   => parse_element(tokens[2], 0..23),
          :dom    => parse_element(tokens[3], 1..31),
          :month  => parse_element(tokens[4], 1..12),
          :dow    => parse_element(tokens[5], 0..6)
        }
      end
  end

  def nudge_second(t, dir = :next)
    spec = time_specs[:second][1]
    next_value = find_best_next(t.sec, spec, dir)
    t.sec = next_value || (dir == :next ? spec.first : spec.last)

    nudge_minute(t, dir) if next_value.nil?
  end

  def next(now = @time_source.now, num = 1)
    t = ExtendedInternalTime.new(now, @time_source)

    unless time_specs[:month][0].include?(t.month)
      nudge_month(t)
      t.day = 0
    end

    unless interpolate_weekdays(t.year, t.month)[0].include?(t.day)
      nudge_date(t)
      t.hour = -1
    end

    unless time_specs[:hour][0].include?(t.hour)
      nudge_hour(t)
      t.min = -1
    end

    unless time_specs[:minute][0].include?(t.min)
      nudge_minute(t)
      t.sec = -1
    end

    # always nudge the second
    nudge_second(t)

    t = t.to_time
    if num > 1
      recursive_calculate(:next, t, num)
    else
      t
    end
  end

  def last(now = @time_source.now, num=1)
    t = ExtendedInternalTime.new(now,@time_source)

    unless time_specs[:month][0].include?(t.month)
      nudge_month(t, :last)
      t.day = 32
    end

    if t.day == 32 || !interpolate_weekdays(t.year, t.month)[0].include?(t.day)
      nudge_date(t, :last)
      t.hour = 24
    end

    unless time_specs[:hour][0].include?(t.hour)
      nudge_hour(t, :last)
      t.min = 60
    end

    unless time_specs[:minute][0].include?(t.min)
      nudge_minute(t, :last)
      t.sec = 60
    end

    # always nudge the second
    nudge_second(t, :last)
    t = t.to_time
    if num > 1
      recursive_calculate(:last, t, num)
    else
      t
    end
  end

  def interpret_vixieisms(spec)
    case spec
    when '@reboot'
      raise ArgumentError, "Can't predict last/next run of @reboot"
    when '@yearly', '@annually'
      '0 0 0 1 1 *'
    when '@monthly'
      '0 0 0 1 * *'
    when '@weekly'
      '0 0 0 * * 0'
    when '@daily', '@midnight'
      '0 0 0 * * *'
    when '@hourly'
      '0 0 * * * *'
    else
      spec
    end
  end
end
