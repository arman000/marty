module Marty::Diagnostic; class Scheduler < Base
  self.aggregatable = false

  diagnostic_fn do
    begin
      sl = Marty::SchedulerLife.last
      st = Marty::Config['SCHEDULER_HEARTBEAT'] || 60

      attrs = {}

      if sl
        attrs += sl.attributes.except('single_row_id')
        attrs['heartbeat'] = error(attrs['heartbeat'].to_s) if
          attrs['heartbeat'] &&
          (attrs['heartbeat'].to_time + st) < Time.now

        ['pid', 'ip', 'heartbeat'].each{
          |a|
          attrs[a] = error("missing #{a}") unless attrs[a]
        }
      else
        attrs['scheduler_life'] = error('SchedulerLife row does not exist.')
      end

      attrs.sort.to_h
    rescue => e
      error(e.message)
    end
  end
end
end
