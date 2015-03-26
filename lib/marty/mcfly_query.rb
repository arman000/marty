require 'mcfly'

module Mcfly
  module Model

    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def clear_lookup_cache!
        @LOOKUP_CACHE.clear if @LOOKUP_CACHE
      end

      # Implements a VERY HACKY class-based caching mechanism for
      # database lookup results.  Issues include: cached values are
      # ActiveRecord objects.  Not sure if these should be shared
      # across connections.  Query results can potentially be very
      # large lists which we simply count as one item in the cache.
      # Caching mechanism will result in large processes.  Caches are
      # not sharable across different Ruby processes.
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

      # FIXME: duplicate code from Mcfly's mcfly_lookup.
      def cached_mcfly_lookup(name, options = {}, &block)
        cached_delorean_fn(name, options) do |ts, *args|
          raise "time cannot be nil" if ts.nil?

          ts = Mcfly.normalize_infinity(ts)

          where("obsoleted_dt >= ? AND created_dt < ?", ts, ts).scoping do
            block.call(ts, *args)
          end
        end
      end

      # FIXME: for validation purposes, this mechanism should make
      # sure that the allable attrs are not required.
      def gen_mcfly_lookup(name, attrs, options={})
        raise "bad options" unless options.is_a?(Hash)

        # FIXME: mode should be sent later, not as a part of
        # gen_mcfly_lookup.  i.e. we just generate the search and the
        # mode is applied at runtime by delorean code.  That would
        # allow lookups to be used in either mode dynamically.
        mode = options.fetch(:mode, :first)

        assoc = Set.new(self.reflect_on_all_associations.map(&:name))
        attr_names = attrs.keys

        allables = attrs.select {|k, v| v}

        order = allables.keys.reverse.map { |k|
          k = "#{k}_id" if assoc.member?(k)
          "#{k} NULLS LAST"
        }.join(", ")

        qstr = attrs.map {|k, v|
          k = "#{k}_id" if assoc.member?(k)
          v ? "(#{k} = ? OR #{k} IS NULL)" : "(#{k} = ?)"
        }.join(" AND ")

        cached_mcfly_lookup(name, sig: attrs.length+1) do
          |t, *attr_list|

          attr_list_ids = attr_list.each_with_index.map {|x, i|
            assoc.member?(attr_names[i]) ?
            (attr_list[i] && attr_list[i].id) : attr_list[i]
          }

          q = self.where(qstr, *attr_list_ids)
          q = q.order(order) unless order.empty?
          mode = :to_a if mode == :all
          mode ? q.send(mode) : q
        end
      end

      ######################################################################

      # Generates categorization lookups.  For instance,
      # suppose we have the following in class GFee:
      #
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

      # In the above case,
      # rel_attr = :security_instrument
      # cat_assoc_klass = Gemini::SecurityInstrumentCategorization
      # cat_attr = :g_fee_category
      # name = :lookup_q
      # pc_name = :pc_lookup_q
      # pc_attrs = {entity: true, security_instrument: true,
      # g_fee_category: true, coupon: true}

      def gen_mcfly_lookup_cat(name, catrel, attrs, options={})
        rel_attr, cat_assoc_name, cat_attr = catrel

        raise "#{rel_attr} should be mapped in attrs" if
          attrs[rel_attr].nil?

        cat_assoc_klass = cat_assoc_name.constantize

        raise "need lookup method on #{cat_assoc_klass}" unless
          cat_assoc_klass.respond_to? :lookup

        # replace rel_attr with cat_attr in attrs
        pc_attrs = attrs.each_with_object({}) {|(k, v), h|
          h[k == rel_attr ? cat_attr : k] = v
        }

        pc_name = "pc_#{name}".to_sym
        gen_mcfly_lookup(pc_name, pc_attrs, options)

        lpi = attrs.keys.index rel_attr

        raise "should not include #{cat_attr}" if
          attrs.member?(cat_attr)

        raise "need #{rel_attr} argument" unless lpi

        delorean_fn(name, sig: attrs.length+1) do |ts, *args|
          # Example: rel is a Gemini::SecurityInstrument instance.
          rel = args[lpi]
          raise "#{rel_attr} can't be nil" unless rel

          # Assumes there's a mcfly :lookup function on
          # cat_assoc_klass.
          categorizing_obj = cat_assoc_klass.lookup(ts, rel)
          raise "no categorization #{cat_assoc_klass} for #{rel}" unless
            categorizing_obj

          pc = categorizing_obj.send(cat_attr)
          raise ("#{categorizing_obj} must have assoc." +
                 " #{cat_attr}/#{rel.inspect}") unless pc

          args[lpi] = pc
          self.send(pc_name, ts, *args)
        end
      end

    end
  end
end

module Mcfly::Controller
  # define mcfly user to be Flowscape's current_user.
  def user_for_mcfly
    find_current_user rescue nil
  end
end
