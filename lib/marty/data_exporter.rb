require 'base64'
require 'zlib'

class Marty::DataExporter
  # given an array of hashes, return set of all keys
  def self.hash_array_keys(hl)
    hl.each_with_object(Set.new) { |h, keys| keys.merge(h.keys) }
  end

  def self.hash_array_merge(hl, transpose)
    # given a list of hashes hl, generates a merged hash.  The
    # resulting hash contains a superset of all the hash keys.  The
    # values are corresponding values from each hash in hl.
    keys = hash_array_keys(hl)

    if transpose
      keys.each_with_object({}) { |k, rh|
        rh[k] = hl.map { |h| h[k] }
      }
    else
      [keys.to_a] + hl.map {|h| keys.map {|k| h[k]}}
    end
  end

  def self.encode_json(s)
    Base64.strict_encode64 Zlib.deflate(s)
  end

  def self.decode_json(s)
    Zlib.inflate Base64.strict_decode64(s)
  end

  def self.to_csv(obj, config=nil)
    obj = [obj] unless obj.respond_to? :map

    config ||= {}

    # if all array items are hashes, we merge them
    obj = hash_array_merge(obj, config["transpose"]) if
      obj.map {|x| x.is_a? Hash}.all?

    # symbolize config keys as expected by CSV.generate
    conf = config.each_with_object({}) { |(k,v), h|
      h[k.to_sym] = v unless k.to_s == "transpose"
    }

    # FIXME: very hacky to default row_sep to CRLF
    conf[:row_sep] ||= "\r\n"

    csv_string = CSV.generate(conf) do |csv|
      obj.each do |x|
        x = [x] unless x.respond_to? :map
        csv << x.map { |v|
          v.is_a?(Array) || v.is_a?(Hash) ? encode_json(v.to_json) : v.to_s
        }
      end
    end
  end

  def self.class_info(klass)
    @class_info ||= {}

    return @class_info[klass] if @class_info[klass]

    associations = klass.reflect_on_all_associations.map(&:name)

    @class_info[klass] = {
      cols:
      klass.columns.map(&:name) - Marty::DataRowProcessor::MCFLY_COLUMNS.to_a,

      assoc:
      associations.each_with_object({}) { |a, h|
        h["#{a}_id"] = Marty::DataRowProcessor.assoc_info(klass, a)
      },
    }
  end

  def self.export_attr(obj, c, info)
    v = obj.send(c.to_sym)
    assoc_info = info[:assoc][c] unless v.nil?
    return [v] unless assoc_info

    assoc_obj = assoc_info[:assoc_class].find(v)

    assoc_info[:assoc_keys].map {|k| assoc_obj.send(k.to_sym)}
  end

  def self.export_header_attr(c, info)
    assoc_info = info[:assoc][c]
    return c unless assoc_info

    # remove _id
    c = c[0..-4]

    assoc_keys = assoc_info[:assoc_keys]

    # FIXME: this doesn't work if k is also an association.  Needs to
    # be recursive.
    assoc_keys.length > 1 ? assoc_keys.map {|k| "#{c}__#{k}"} : c
  end

  # Given a Mcfly klass, generate an export array.  Can potentially
  # use up a lot of memory if the result set is large.
  def self.do_export(ts, klass, sort_field=nil)
    info = class_info(klass)

    # strip _id from assoc fields
    header = [ info[:cols].map {|c| export_header_attr(c, info)}.flatten(1) ]

    ts = Mcfly.normalize_infinity(ts)

    header + klass.where("obsoleted_dt >= ? AND created_dt < ?", ts, ts).
      order(sort_field || :id).all.
      map {|obj| info[:cols].map {|c| export_attr(obj, c, info)}.flatten(1)}
  end
end
