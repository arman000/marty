class Marty::DataExporter
  def self.hash_array_merge(*hl)
    # given a list of hashes hl, generates a merged hash.  The
    # resulting hash contains a superset of all the hash keys.  The
    # values are corresponding values from each hash in hl.
    keys = Set.new
    hl.each { |h| keys.merge(h.keys) }

    keys.each_with_object({}) { |k, rh|
      rh[k] = hl.map { |h| h[k] }
    }
  end

  def self.to_csv(obj)
    obj = [obj] unless obj.respond_to? :map

    # if all array items are hashes, we merge them
    obj = hash_array_merge(*obj) if
      obj.map {|x| x.is_a? Hash}.all?

    csv_string = CSV.generate do |csv|
      obj.each { |x|
        x = [x] unless x.respond_to? :map
        csv << x.flatten(1).map(&:to_s)
      }
    end
  end

  def self.class_info(klass)
    @class_info ||= {}

    return @class_info[klass] if @class_info[klass]

    associations = klass.reflect_on_all_associations.map(&:name)

    @class_info[klass] = {
      cols:
      klass.columns.map(&:name) - Marty::DataImporter::MCFLY_COLUMNS.to_a,
      assoc:
      associations.each_with_object({}) { |a, h|
        h["#{a}_id"] = Marty::DataImporter::RowProcessor.assoc_info(klass, a)
      },
    }
  end

  def self.export_attr(obj, c, info)
    v = obj.send(c.to_sym)
    assoc_info = info[:assoc][c] unless v.nil?
    assoc_info ? assoc_info[:assoc_class].find(v).
      send(assoc_info[:assoc_key].to_sym) : v
  end

  # Given a Mcfly klass, generate an export array.  Can potentially
  # use up a lot of memory if the result set is large.
  def self.do_export(ts, klass)
    info = class_info(klass)

    # strip _id from assoc fields
    header = [ info[:cols].map { |c| info[:assoc][c] ? c[0..-4] : c } ]

    ts = (ts == Float::INFINITY) ? 'infinity' : ts

    header + klass.where("obsoleted_dt >= ? AND created_dt < ?", ts, ts).all.
      map {|obj| info[:cols].map {|c| export_attr(obj, c, info)}}
  end

end
