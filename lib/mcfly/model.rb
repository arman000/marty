require 'mcfly'

module Mcfly::Model
  def self.included(base)
    base.send :extend, ClassMethods
  end

  module ClassMethods
    def openstruct_if_necessary(q, private_lookup)
      return q if private_lookup
      return q unless q.is_a?(ActiveRecord::Base)

      warning = 'Mcfly::Model#openstruct_if_necessary is deprecated.' \
        "Please use 'to_hash: true' or 'private: true' option instead"

      Rails.logger.warn warning

      make_openstruct(q)
    end

    def hash_if_necessary(q, to_hash)
      return make_hash(q) if to_hash && q.is_a?(ActiveRecord::Base)

      q
    end

    def base_mcfly_lookup(name, options = {})
      delorean_options = {
        # private: options.fetch(:private, false),
        cache: options.fetch(:cache, false),
        sig: options[:sig]
      }

      delorean_fn name, delorean_options do |ts, *args|
        raise 'time cannot be nil' if ts.nil?

        # FIXME: sig is removed from delorean. We need to find a better way
        # to control amount of arguments, instead of using *splat arguments.
        max_args = Array(options[:sig]).max if options[:sig]
        if max_args && (args.size + 1) > max_args
          err = "Too many args to #{name}." \
            "(given #{args.size + 1}, expected #{max_args})"

          raise ArgumentError, err
        end

        ts = Mcfly.normalize_infinity(ts)
        q = where("#{table_name}.obsoleted_dt >= ? AND " +
                   "#{table_name}.created_dt < ?", ts, ts).scoping do
          yield(ts, *args)
        end

        fa = get_final_attrs
        q = q.select(*fa) if fa.present? && q.is_a?(ActiveRecord::Relation)

        q = q.first if q.respond_to?(:first) && options[:mode] == :first

        if options[:to_hash]
          next hash_if_necessary(
            q,
            options.fetch(:to_hash, false)
          )
        end

        openstruct_if_necessary(q, options[:private])
      end
    end

    def cached_mcfly_lookup(name, options = {}, &block)
      base_mcfly_lookup(name, options.merge(cache: true), &block)
    end

    def mcfly_lookup(name, options = {}, &block)
      base_mcfly_lookup(name, options, &block)
    end

    def gen_mcfly_lookup(name, attrs, options = {})
      raise "bad options #{options.keys}" unless
      (options.keys - [:mode, :cache, :private, :to_hash]).empty?

      mode = options.fetch(:mode, :first)

      # if mode is nil, don't cache -- i.e. don't cache AR queries
      cache = mode && options[:cache]

      # the older mode=:all is not supported (it's bogus)
      raise "bad mode #{mode}" unless [nil, :first].member?(mode)

      assoc = Set.new(reflect_on_all_associations.map(&:name))

      qstr = attrs.map do |k, v|
        k = "#{k}_id" if assoc.member?(k)

        v ? "(#{k} = ? OR #{k} IS NULL)" : "(#{k} = ?)"
      end.join(' AND ')

      if attrs.is_a?(Hash)
        order = attrs.select { |_k, v| v }.keys.reverse.map do |k|
          k = "#{k}_id" if assoc.member?(k)

          "#{k} NULLS LAST"
        end.join(', ')
        attrs = attrs.keys
      else
        raise 'bad attrs' unless attrs.is_a?(Array)
      end

      base_mcfly_lookup(name, options + { sig:  attrs.length + 1,
                                             mode: mode }) do |_t, *attr_list|
        attr_list_ids = attr_list.each_with_index.map do |_x, i|
          assoc.member?(attrs[i]) ?
            attr_list[i]&.id : attr_list[i]
        end

        q = where(qstr, *attr_list_ids)
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

    def gen_mcfly_lookup_cat(name, catrel, attrs, options = {})
      rel_attr, cat_assoc_name, cat_attr = catrel

      raise "#{rel_attr} should be mapped in attrs" if attrs[rel_attr].nil?

      cat_assoc_klass = cat_assoc_name.constantize
      cat_attr_id = "#{cat_attr}_id"

      # replace rel_attr with cat_attr in attrs
      pc_attrs = attrs.each_with_object({}) do |(k, v), h|
        h[k == rel_attr ? cat_attr_id : k] = v
      end

      pc_name = "pc_#{name}".to_sym

      gen_mcfly_lookup(pc_name, pc_attrs, options + { private: true, to_hash: false })

      lpi = attrs.keys.index rel_attr

      raise "should not include #{cat_attr}" if attrs.member?(cat_attr)
      raise "need #{rel_attr} argument" unless lpi

      # cache if mode is not nil
      to_hash = options.fetch(:to_hash, false)

      # cache if mode is not explicitly set to nil or cache is true
      cache = options.fetch(:cache) { options.fetch(:mode, :first) }

      delorean_options = {
        # private: options.fetch(:private, false),
        cache: cache.present?, # convert to bool
        sig: attrs.length + 1
      }

      delorean_fn name, delorean_options do |ts, *args|
        # Example: rel is a Gemini::SecurityInstrument instance.
        rel = args[lpi]
        raise "#{rel_attr} can't be nil" unless rel

        args[lpi] = cat_assoc_klass.
                      mcfly_pt(ts).
                      select(cat_attr_id).
                      find_by(rel_attr => rel).
                      send(cat_attr_id)

        q = send(pc_name, ts, *args)

        if to_hash
          next hash_if_necessary(
            q,
            options.fetch(:to_hash, false)
          )
        end

        openstruct_if_necessary(q, options[:private])
      end
    end
  end
end
