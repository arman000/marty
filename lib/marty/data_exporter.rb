require 'base64'
require 'zlib'
require 'csv'
require 'marty/data_conversion'

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

    return keys.each_with_object({}) { |k, rh|
        rh[k] = hl.map { |h| h[k] }
    } if transpose

    [keys.to_a] + hl.map {|h| keys.map {|k| h[k]}}
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
      obj.is_a?(Array) && obj.map {|x| x.is_a? Hash}.all?

    # symbolize config keys as expected by CSV.generate
    conf = config.each_with_object({}) { |(k,v), h|
      h[k.to_sym] = v unless k.to_s == "transpose"
    }

    # FIXME: very hacky to default row_sep to CRLF
    conf[:row_sep] ||= "\r\n"

    # FIXME: the following is ridiculously complex. We have different
    # data paths for hashes and arrays.  Also, arrays can turn into
    # hashes is all their items are hashes!  We map to complex objects
    # to JSON when inside hashes, but not arrays. Really need to
    # rethink this.  Probably should have separate functions for
    # to_csv for hash and arrays.

    return CSV.generate(conf) do |csv|
      obj.each do |x|
        csv << x.flatten(1).map(&:to_s)
      end
    end if obj.is_a?(Hash)

    CSV.generate(conf) do |csv|
      obj.each do |x|
        x = [x] unless x.respond_to? :map
        csv << x.map { |v|
          v.is_a?(Array) || v.is_a?(Hash) ? encode_json(v.to_json) : v.to_s
        }
      end
    end
  end

  def self.export_attrs(klass, obj)
    col_types = Marty::DataConversion.col_types(klass)

    col_types.map do
      |c, type|
      v = obj.send(c.to_sym)

      # return [value] if not assoc or nil
      next [v] if v.nil? || !type.is_a?(Hash)

      assoc_obj = type[:assoc_class].find(v)
      type[:assoc_keys].map {|k| assoc_obj.send(k.to_sym)}
    end
  end

  def self.export_header_attrs(klass)
    col_types = Marty::DataConversion.col_types(klass)

    col_types.map do
      |c, type|
      next c unless type.is_a?(Hash)

      # remove _id
      c = c[0..-4]

      assoc_keys = type[:assoc_keys]

      # FIXME: this doesn't work if k is also an association.  Needs to
      # be recursive.
      assoc_keys.length > 1 ? assoc_keys.map {|k| "#{c}__#{k}"} : c
    end
  end

  # Given a Mcfly klass, generate an export array.  Can potentially
  # use up a lot of memory if the result set is large.
  def self.do_export(ts, klass, sort_field=nil)
    query = klass

    if Mcfly.has_mcfly?(klass)
      ts = Mcfly.normalize_infinity(ts)
      query = query.where("obsoleted_dt >= ? AND created_dt < ?", ts, ts)
    end

    do_export_query_result(klass, query.order(sort_field || :id))
  end

  def self.do_export_query_result(klass, qres)
    # strip _id from assoc fields
    header = [ export_header_attrs(klass).flatten(1) ]

    header + qres.map {|obj| export_attrs(klass, obj).flatten(1)}
  end
end
