# Various monkey patches go here

######################################################################

require 'delorean_lang'

# Be able to access Enums from Delorean
class Delorean::BaseModule::BaseClass
  class << self
    alias_method :old_get_attr, :_get_attr

    def _get_attr(obj, attr, _e)
      if (Marty::Enum === obj ||
          Marty::PgEnum === obj) && !obj.respond_to?(attr)
        obj[attr]
      else
        old_get_attr(obj, attr, _e)
      end
    end
  end
end

######################################################################

class Hash
  # define addition on hashes -- useful in Delorean code.
  def +(x)
    self.merge(x)
  end

  # define hash slice (similar to node slice in Delorean)
  def %(x)
    x.each_with_object({}) do |k, h|
      h[k] = self[k]
    end
  end
end

######################################################################

require 'netzke-basepack'

class Netzke::Base
  # get root component session
  def root_sess(component = nil)
    component ||= self
    component.parent ? root_sess(component.parent) : component.component_session
  end
end

######################################################################

# The following is a hack to get around ActiveRecord's broken handling
# of PostgreSQL ranges.  Essentially, AR doesn't allow numranges to
# exclude the range start e.g. anything like: "(1.1,2.2]".  This hack
# turns off the casting of PostgreSQL ranges to ruby ranges. i.e. we
# keep them as strings.

require 'active_record/connection_adapters/postgresql_adapter'

module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      module OID
        class Range
          def cast_value(value)
            super
          end

          def deserialize(value)
            super
          end
        end
      end
    end
  end
end

######################################################################

# Rails 4 doesn't handle 'infinity' datetime properly due to
# in_time_zone conversion. Ergo this hack.

class String
  alias_method :old_in_time_zone, :in_time_zone

  def in_time_zone(zone = ::Time.zone)
    self == 'infinity' ? self : old_in_time_zone(zone)
  end

end

######################################################################

# Axlsx::sanitize modifies strings in worksheet definition -- this
# doesn't work with Delorean's frozen strings.
require 'axlsx'
module Axlsx
  def self.sanitize(str)
    str.delete(CONTROL_CHARS)
  end
end

######################################################################

require 'netzke/basepack/data_adapters/active_record_adapter'
module Netzke::Basepack::DataAdapters
  class ActiveRecordAdapter < AbstractAdapter
    ######################################################################
    # The following is a hack to get around Netzke's broken handling
    # of filtering on PostgreSQL enums columns.
    def predicates_for_and_conditions(conditions)
      return nil if conditions.empty?

      predicates = conditions.map do |q|
        q = HashWithIndifferentAccess.new(Netzke::Support.permit_hash_params(q))

        attr = q[:attr]
        method, assoc = method_and_assoc(attr)

        arel_table = assoc ? Arel::Table.new(assoc.klass.table_name.to_sym) :
                       @model.arel_table

        value = q["value"]
        op = q["operator"]

        attr_type = attr_type(attr)

        case attr_type
        when :datetime
          update_predecate_for_datetime(arel_table[method], op, value.to_date)
        when :string, :text
          update_predecate_for_string(arel_table[method], op, value)
        when :boolean
          update_predecate_for_boolean(arel_table[method], op, value)
        when :date
          update_predecate_for_rest(arel_table[method], op, value.to_date)
        when :enum
          # HACKY! monkey patching happens here...
          update_predecate_for_enum(arel_table[method], op, value)
        else
          update_predecate_for_rest(arel_table[method], op, value)
        end
      end

      # join them by AND
      predicates[1..-1].inject(predicates.first) { |r, p| r.and(p)  }
    end

    def update_predecate_for_enum(table, op, value)
      col = Arel::Nodes::NamedFunction.new("CAST", [table.as("TEXT")])
      col.matches "%#{value}%"
    end
  end
end

######################################################################

# Add pg_enum migration support -- FIXME: this doesn't belong here
module ActiveRecord
  module ConnectionAdapters
    class TableDefinition
      def pg_enum(*args)
        options = args.extract_options!
        column_names = args

        enum = options.delete(:enum)

        column_names.each do |name|
          column(name, enum || name.to_s.pluralize, options)
        end
      end
    end
  end
end

######################################################################

class ActiveRecord::Relation
  def mcfly_pt(pt, cls = nil)
    cls ||= self.klass
    tb = cls.table_name
    self.where("#{tb}.obsoleted_dt >= ? AND #{tb}.created_dt < ?", pt, pt)
  end

  def attributes
    to_a.map(&:attributes)
  end
end

######################################################################

require 'marty/cache_adapters'

class ActiveRecord::Base
  MCFLY_PT_SIG = [1, 1]

  # FIXME: hacky signatures for AR queries on classes
  COUNT_SIG    = [0, 0]
  DISTINCT_SIG = [0, 100]
  FIND_BY_SIG  = [0, 100]
  FIRST_SIG    = [0, 1]
  GROUP_SIG    = [1, 100]
  JOINS_SIG    = [1, 100]
  LAST_SIG     = [0, 1]
  LIMIT_SIG    = [1, 1]
  NOT_SIG      = [1, 100]
  ORDER_SIG    = [1, 100]
  PLUCK_SIG    = [1, 100]
  SELECT_SIG   = [1, 100]
  WHERE_SIG    = [0, 100]

  class << self
    alias_method :old_joins, :joins

    def joins(*args)
      # when joins args are strings, checks to see if they're
      # associations attrs.  If so, convert them to symbols for joins
      # to work properly.
      new_args = args.map do |a|
        self.reflections.has_key?(a) ? a.to_sym : a
      end
      old_joins(*new_args)
    end
  end
end

ar_instances = [ActiveRecord::Relation, ActiveRecord::QueryMethods::WhereChain]

args_hack = [[Object, nil]] * 10

[[:distinct, args_hack],
 [:find_by,  args_hack],
 [:group,    args_hack],
 [:joins,    args_hack],
 [:limit,    [Integer]],
 [:not,      args_hack],
 [:order,     args_hack],
 [:pluck,     args_hack],
 [:select,    args_hack],
 [:where,     args_hack],
 [:mcfly_pt, [[Date, Time, ActiveSupport::TimeWithZone, String], [nil, Class]]]
].each do |meth, args|
  ::Delorean::Ruby.whitelist.add_method meth do |method|
    ar_instances.each do |ar|
      method.called_on ar, with: args
    end
  end
end
::Delorean::Ruby.whitelist.add_method :count do |method|
    ar_instances.each do |ar|
      method.called_on ar
    end
end
::Delorean::Ruby.whitelist.add_method :lookup_grid_distinct_entry do |method|
  method.called_on OpenStruct, with: [[Date, Time,
                                       ActiveSupport::TimeWithZone, String],
                                        Hash]
end


mcfly_cache_adapter = ::Marty::CacheAdapters::McflyRubyCache.new(
  size_per_class: 1000
)

::Delorean::Cache.adapter = mcfly_cache_adapter

######################################################################

module Mcfly::Controller
  # define mcfly user to be Flowscape's current_user.
  def user_for_mcfly
    find_current_user rescue nil
  end
end

######################################################################

class OpenStruct
  # the default as_json produces {"table"=>h} which is quite goofy
  def as_json(*)
    self.to_h
  end
end

######################################################################

module Netzke
  module Core
    module DynamicAssets
      class << self
        def minify_js(js_string)
          if ::Rails.env.test? || ::Rails.env.development?
            js_string.gsub(/\/\*\*[^*]*\*+(?:[^*\/][^*]*\*+)*\//, '') # strip docs
          else
            # MONKEY: enable es6 by passing in harmony argument
            Uglifier.compile(js_string, harmony: true)
          end
        end
      end
    end
  end
end
