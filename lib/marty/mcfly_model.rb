require 'mcfly'

module Mcfly::Model
  def self.included(base)
    base.send :extend, ClassMethods
  end

  module ClassMethods
    def hash_if_necessary(q, private)
      !private && q.is_a?(ActiveRecord::Base) ? make_openstruct(q) : q
    end

    def base_mcfly_lookup(meth, name, options = {}, &block)

      priv = options[:private]

      send(meth, name, options) do |ts, *args|
        raise "time cannot be nil" if ts.nil?

        ts = Mcfly.normalize_infinity(ts)
        q = self.where("#{table_name}.obsoleted_dt >= ? AND " +
                   "#{table_name}.created_dt < ?", ts, ts).scoping do
          block.call(ts, *args)
        end

        fa = get_final_attrs
        q = q.select(*fa) if fa.present? && q.is_a?(ActiveRecord::Relation)

        q = q.first if q.respond_to?(:first) && options[:mode] == :first

        hash_if_necessary(q, priv)
      end
    end

    def cached_mcfly_lookup(name, options = {}, &block)
      base_mcfly_lookup(:cached_delorean_fn, name, options, &block)
    end

    def mcfly_lookup(name, options = {}, &block)
      base_mcfly_lookup(:delorean_fn, name, options, &block)
    end

    def gen_mcfly_lookup(name, attrs, options={})
      raise "bad options #{options.keys}" unless
        (options.keys - [:mode, :cache, :private]).empty?

      mode = options.fetch(:mode, :first)

      # if mode is nil, don't cache -- i.e. don't cache AR queries
      cache = mode && options[:cache]

      # the older mode=:all is not supported (it's bogus)
      raise "bad mode #{mode}" unless [nil, :first].member?(mode)

      assoc = Set.new(self.reflect_on_all_associations.map(&:name))

      qstr = attrs.map do |k, v|
        k = "#{k}_id" if assoc.member?(k)

        v ? "(#{k} = ? OR #{k} IS NULL)" : "(#{k} = ?)"
      end.join(" AND ")

      if Hash === attrs
        order = attrs.select {|k, v| v}.keys.reverse.map do |k|
          k = "#{k}_id" if assoc.member?(k)

          "#{k} NULLS LAST"
        end.join(", ")
        attrs = attrs.keys
      else
        raise "bad attrs" unless Array === attrs
      end

      fn = cache ? :cached_delorean_fn : :delorean_fn
      base_mcfly_lookup(fn, name, options + {sig:  attrs.length+1,
                                             mode: mode}) do |t, *attr_list|

        attr_list_ids = attr_list.each_with_index.map do |x, i|
          assoc.member?(attrs[i]) ?
            (attr_list[i] && attr_list[i].id) : attr_list[i]
        end

        q = self.where(qstr, *attr_list_ids)
        q = q.order(order) if order
        q
      end
    end

    ######################################################################

    # Generates categorization lookups, e.g. given class GFee:

    # gen_mcfly_lookup_cat :lookup_q,
    # [:security_instrument,
    #  'Gemini::SecurityInstrumentCategorization',
    #  :g_fee_category],
    # {
    #   entity: true,
    #   security_instrument: true,
    #   coupon: true,
    # },
    # nil

    # rel_attr        = :security_instrument
    # cat_assoc_klass = Gemini::SecurityInstrumentCategorization
    # cat_attr        = :g_fee_category
    # name            = :lookup_q
    # pc_name         = :pc_lookup_q
    # pc_attrs        = {entity: true, security_instrument: true, coupon: true}

    def gen_mcfly_lookup_cat(name, catrel, attrs, options={})
      rel_attr, cat_assoc_name, cat_attr = catrel

      raise "#{rel_attr} should be mapped in attrs" if attrs[rel_attr].nil?

      cat_assoc_klass = cat_assoc_name.constantize
      cat_attr_id = "#{cat_attr}_id"

      # replace rel_attr with cat_attr in attrs
      pc_attrs = attrs.each_with_object({}) do |(k, v), h|
        h[k == rel_attr ? cat_attr_id : k] = v
      end

      pc_name = "pc_#{name}".to_sym

      gen_mcfly_lookup(pc_name, pc_attrs, options + {private: true})

      lpi = attrs.keys.index rel_attr

      raise "should not include #{cat_attr}" if attrs.member?(cat_attr)
      raise "need #{rel_attr} argument" unless lpi

      # cache if mode is not nil
      fn = options.fetch(:mode, :first) ? :cached_delorean_fn : :delorean_fn
      priv = options[:private]

      send(fn, name, sig: attrs.length+1) do |ts, *args|
        # Example: rel is a Gemini::SecurityInstrument instance.
        rel = args[lpi]
        raise "#{rel_attr} can't be nil" unless rel

        args[lpi] = cat_assoc_klass.
                      mcfly_pt(ts).
                      select(cat_attr_id).
                      find_by(rel_attr => rel).
                      send(cat_attr_id)

        q = self.send(pc_name, ts, *args)
        hash_if_necessary(q, priv)
      end
    end
  end
end
