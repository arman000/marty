class Marty::ApiLog < Marty::Base
  validates_presence_of :script, :node, :attrs, :start_time, :end_time,
                        :remote_ip

end
