module Marty::Diagnostic::Packer
  # expects a block that returns either a String or a Hash value and formats
  # it into a diagnostic info object.
  def pack include_ip=true
    begin
      data = yield
      info = case data
             when Hash
               is_valid_info?(data) ? {name.demodulize => data} :
                 data.each_with_object({}) do
                 |(key, value), hash|
                 case value
                 when String
                   hash[key] = create_info(value)
                 when Hash
                   raise "Invalid Diagnostic Info #{value}" unless
                     is_valid_info?(value)

                   hash[key] = value
                 end
               end
             when String
               {name.demodulize => create_info(data)}
             else
               raise "Invalid Data Type: (#{data}, #{data.class}) "\
                     "`package` expects a String or Hash value."
             end
      include_ip ? {Marty::Diagnostic::Node.my_ip => info} : info
    end
  end

  def create_info description, status=true, consistent=nil
    {
      'description' => description,
      'status' => status,
      'consistent' => consistent
    }
  end

  def is_valid_info? info
    info.keys.to_set == Set['description', 'status', 'consistent']
  end

  def error description
    create_info(description, false)
  end
end
