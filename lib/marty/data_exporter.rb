class Marty::DataExporter
  # given an array of hashes, return set of all keys
  def self.hash_array_keys(hl)
    hl.each_with_object(Set.new) { |h, keys| keys.merge(h.keys) }
  end

  def self.hash_array_merge(hl, transpose)
    # given a list of hashes hl, generates a merged hash.  The
    # resulting hash contains a superset of all the hash keys.  The
    # values are corresponding values from each hash in hl.
    # e.g. the following
    #
    # [{"a"=>1, "b"=>2}, {"a"=>11, "c"=>33}, {"a"=>1111, "b"=>222, "c"=>333}]
    #
    # maps to ...
    #
    # [["a", "b", "c"], [1, 2, nil], [11, nil, 33], [1111, 222, 333]]

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
        csv << x.flatten(1).map { |v| v.nil? ? nil : v.to_s }
      end
    end if obj.is_a?(Hash)

    CSV.generate(conf) do |csv|
      obj.each do |x|
        x = [x] unless x.respond_to? :map
        csv << x.map { |v|
          case v
          when Array, Hash
            encode_json(v.to_json)
          when nil
            nil
          else
            v.to_s
          end
        }
      end
    end
  end

  def self.export_attrs(klass, obj, attrs=nil, exclude_attrs=[])
    col_types = Marty::DataConversion.col_types(klass)

    attr_list = (attrs || col_types.keys).map(&:to_s) - exclude_attrs

    attr_list.map do
      |c|

      v = obj.send(c.to_sym)

      type = col_types[c]

      # return [value] if not assoc or nil
      next [v] if v.nil? || !type.is_a?(Hash)

      assoc_keys  = type[:assoc_keys]
      assoc_class = type[:assoc_class]
      assoc_obj   = assoc_class.find(v)

      # FIXME: this recursion will fail if a reference which then
      # makes sub-references is nil.  To handle this, we'd need to
      # create the export structure first.
      export_attrs(assoc_class, assoc_obj, assoc_keys).flatten(1)
    end
  end

  def self.export_headers(klass, attrs=nil, exclude_attrs=[])
    col_types = Marty::DataConversion.col_types(klass)

    attr_list = (attrs || col_types.keys).map(&:to_s) - exclude_attrs

    attr_list.map do
      |c|

      type = col_types[c]

      next c unless type.is_a?(Hash)

      # remove _id
      c = c[0..-4]

      assoc_keys = type[:assoc_keys]

      # if association has a single key, just use col name
      next c if assoc_keys.length == 1

      assoc_class = type[:assoc_class]

      export_headers(assoc_class, assoc_keys).map {|k| "#{c}__#{k}"}
    end
  end

  # Given a Mcfly klass, generate an export array.  Can potentially
  # use up a lot of memory if the result set is large.
  def self.do_export(ts, klass, sort_field=nil, exclude_attrs=[])
    query = klass

    if Mcfly.has_mcfly?(klass)
      ts = Mcfly.normalize_infinity(ts)
      query = query.where("obsoleted_dt >= ? AND created_dt < ?", ts, ts)
    end

    do_export_query_result(klass, query.order(sort_field || :id), exclude_attrs)
  end

  def self.do_export_query_result(klass, qres, exclude_attrs=[])
    # strip _id from assoc fields
    header = [ export_headers(klass, nil, exclude_attrs).flatten ]

    header + qres.map {|obj|
      export_attrs(klass, obj, nil, exclude_attrs).flatten(1)
    }
  end

  # Export a single object to hash -- FIXME: inefficient
  # implementation
  def self.export_obj(obj)
    klass = obj.class
    headers = export_headers(klass)
    rec = export_attrs(klass, obj).flatten
    Hash[ headers.zip(rec) ]
  end
end
