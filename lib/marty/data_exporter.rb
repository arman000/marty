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

end
