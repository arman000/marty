module Marty::Diagnostic; module Packer
  def pack include_ip=true
    info = process(yield)
    include_ip ? {Node.my_ip => info} : info
  end

  def process obj
    obj.is_a?(Hash) ? process_hash(obj) :
      {name.demodulize => create_info(obj.to_s)}
  end

  def process_hash data
    return {name.demodulize => data} if is_valid_info?(data)

    data.each_with_object({}) do |(k, v), h|
      if v.is_a?(Hash)
        raise "Invalid Diagnostic Info #{v}" unless is_valid_info?(v)
        h[k] = v
      else
        h[k] = create_info(v)
      end
    end
  end

  def create_info description, status=true, consistent=nil
    {
      'description' => description.to_s,
      'status'      => status,
      'consistent'  => consistent
    }
  end

  def is_valid_info? info
    info.keys.to_set == Set['description', 'status', 'consistent']
  end

  def error description
    create_info(description, false)
  end
end
end
