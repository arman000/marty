require 'mcfly'

module Mcfly::Model
  def self.included(base)
    base.send :extend, ClassMethods
  end

  module ClassMethods
    def clear_lookup_cache!
      @LOOKUP_CACHE.clear if @LOOKUP_CACHE
    end

    # FIXME IDEA: we just make :cache an argument to delorean_fn.
    # That way, we don't need the cached_ flavors.  It'll make all
    # this code a lot simpler.  We should also just add the :private
    # mechanism here.

    # Implements a VERY HACKY class-based (per process) caching
    # mechanism for database lookup results.  Issues include: cached
    # values are ActiveRecord objects.  Query results can be very
    # large lists which we count as one item in the cache.  Caching
    # mechanism will result in large processes.
    def cached_delorean_fn(name, options = {}, &block)
      @LOOKUP_CACHE ||= {}

      delorean_fn(name, options) do |ts, *args|
        cache_key = [name, ts] + args.map{ |a|
          a.is_a?(ActiveRecord::Base) ? a.id : a
        } unless Mcfly.is_infinity(ts)
        next @LOOKUP_CACHE[cache_key] if
          cache_key && @LOOKUP_CACHE.has_key?(cache_key)

        res = block.call(ts, *args)

        if cache_key
          # Cache has >1000 items, clear out the oldest 200.  FIXME:
          # hard-coded, should be configurable.  Cache
          # size/invalidation should be per lookup and not class.
          # We're invalidating cache items simply based on age and
          # not usage.  This is faster but not as fair.
          if @LOOKUP_CACHE.count > 1000
            @LOOKUP_CACHE.keys[0..200].each{|k| @LOOKUP_CACHE.delete(k)}
          end
          @LOOKUP_CACHE[cache_key] = res

          # Since we're caching this object and don't want anyone
          # changing it.  FIXME: ideally should freeze this object
          # recursively.
          res.freeze unless res.is_a?(ActiveRecord::Relation)
        end
        res
      end
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
        next q if priv

        fa = get_final_attrs
        q = q.select(*fa) if fa.present? && q.is_a?(ActiveRecord::Relation)

        case
        when q.is_a?(ActiveRecord::Relation)
          # shouldn't happen - lookups that are mode nil should be
          # private raise "#{self}.#{name} can't convert
          # ActiveRecord::Relation to OpenStruct"
          q
        when q.is_a?(ActiveRecord::Base)
          make_openstruct(q)
        else
          q
        end
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

      qstr = attrs.map {|k, v|
        k = "#{k}_id" if assoc.member?(k)

        v ? "(#{k} = ? OR #{k} IS NULL)" : "(#{k} = ?)"
      }.join(" AND ")

      if Hash === attrs
        order = attrs.select {|k, v| v}.keys.reverse.map { |k|
          k = "#{k}_id" if assoc.member?(k)

          "#{k} NULLS LAST"
        }.join(", ")
        attrs = attrs.keys
      else
        raise "bad attrs" unless Array === attrs
      end

      fn = cache ? :cached_delorean_fn : :delorean_fn
      base_mcfly_lookup(fn, name, options + {sig: attrs.length+1}) do
        |t, *attr_list|

        attr_list_ids = attr_list.each_with_index.map {|x, i|
          assoc.member?(attrs[i]) ?
            (attr_list[i] && attr_list[i].id) : attr_list[i]
        }

        q = self.where(qstr, *attr_list_ids)
        q = q.order(order) if order
        mode ? q.send(mode) : q
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

      # replace rel_attr with cat_attr in attrs
      pc_attrs = attrs.each_with_object({}) {|(k, v), h|
        h[k == rel_attr ? "#{cat_attr}_id" : k] = v
      }

      pc_name = "pc_#{name}".to_sym

      gen_mcfly_lookup(pc_name, pc_attrs, options + {private: true})

      lpi = attrs.keys.index rel_attr

      raise "should not include #{cat_attr}" if attrs.member?(cat_attr)
      raise "need #{rel_attr} argument" unless lpi

      # cache if mode is not nil
      fn = options.fetch(:mode, :first) ? :cached_delorean_fn : :delorean_fn

      send(fn, name, sig: attrs.length+1) do
        |ts, *args|

        # Example: rel is a Gemini::SecurityInstrument instance.
        rel = args[lpi]
        raise "#{rel_attr} can't be nil" unless rel

        args[lpi] = cat_assoc_klass.
                      mcfly_pt(ts).
                      # FIXME: XXXX why is this join needed???
                      # joins(cat_attr).
                      where(rel_attr => rel).
                      pluck("#{cat_attr}_id").
                      first

        self.send(pc_name, ts, *args)
      end
    end
  end
end
