module Marty::RSpec::StructureCompare
  def self.struct_compare_all(v1raw, v2raw, key=nil, cmp_opts={}, path=[], errs=[])
    pathstr = path.map(&:to_s).join
    v1,v2 = [v1raw, v2raw].map { |v|
              v.class == ActiveSupport::TimeWithZone ?
                                   DateTime.parse(v.to_s) : v
    }

    return errs + [v1["error"]] if
      v1.class != v2.class && v1.class == Hash && v1["error"]

    return errs + [v2["error"]] if
      v1.class != v2.class && v2.class == Hash && v2["error"]

    return errs + ["path=#{pathstr} class mismatch #{v1.class} #{v2.class}"] unless
      v1.class == v2.class ||
      (!cmp_opts["float_int_nomatch"] &&
       [v1,v2].map(&:class).to_set == Set.new([Integer, Float]))

    override = (cmp_opts["ignore"]||[]).include?(key)
    case v1
    when String
      return errs + ["path=#{pathstr} #{v1} != #{v2}"] unless
        v1 == v2 ||
        Regexp.new('\A'+v1+'\z').match(v2) ||
        Regexp.new('\A'+v2+'\z').match(v1) ||
        override
    when Integer, DateTime, TrueClass, FalseClass, NilClass
      return errs + ["path=#{pathstr} #{v1} != #{v2}"] if v1 != v2 && !override
    when Float
      return errs + ["path=#{pathstr} #{v1} != #{v2}"] if
        v1.round(6) != v2.round(6) && !override
    when Hash
      v1_v2, v2_v1 = v1.keys-v2.keys, v2.keys-v1.keys

      errs.append("path=#{pathstr} hash extra keys #{v1_v2}") unless v1_v2.empty?
      errs.append("path=#{pathstr} hash extra keys #{v2_v1}") unless v2_v1.empty?

      return errs + v1.map do |childkey, childval|
        struct_compare_all(childval, v2[childkey], childkey, cmp_opts,
                           path + [[childkey]], [])
      end.flatten
    when Array
      errs.append(
        "path=#{pathstr} array size mismatch #{v1.size} != #{v2.size}") if
        v1.size != v2.size
      return errs + v1.each_with_index.map do |childval,index|
        struct_compare_all(childval, v2[index], nil, cmp_opts, path + [[index]],
                           [])
      end.flatten
    else
      raise "unhandled #{v1.class}"
    end
    errs
  end
end

def struct_compare(v1raw, v2raw, cmp_opts={})
  begin
    res = Marty::RSpec::StructureCompare.struct_compare_all(v1raw, v2raw, nil,
                                                            cmp_opts).first
  rescue => e
    e.message
  end
end
def struct_compare_all(v1raw, v2raw, cmp_opts={})
  begin
    Marty::RSpec::StructureCompare.struct_compare_all(v1raw, v2raw, nil,
                                                      cmp_opts)
  rescue => e
    e.message
  end
end
