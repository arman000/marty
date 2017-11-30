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
    x.each_with_object({}) { |k, h|
      h[k] = self[k]
    }
  end
end

######################################################################

require 'netzke-basepack'

class Netzke::Base
  # get root component session
  def root_sess(component=nil)
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

          def type_cast_for_database(value)
            super
          end
        end
      end
    end
  end
end


module ActiveRecord
  module ConnectionAdapters
    module PostgreSQL
      module OID # :nodoc:
        class Array

          # In the 4.2.1 version of this code, under Mutable, the code
          # checks for raw_old_value != type_cast_for_database(new_value)
          #
          # Since this is comparing db (string) version, we end up
          # comparing "{1}"!="{1.0}" for float arrays. The following
          # is a hack to check the new_value which is the ruby array.
          # This could be problematic in other ways.  But, works for
          # our purposes.  FIXME: In Rails 5.0 all this code has been
          # changed and this should no longer be an issue.


          def changed_in_place?(raw_old_value, new_value)
            new_value != type_cast_from_database(raw_old_value)
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
    # FIXME: another giant hack to handle lazy_load columns.
    # Modified original count_records to call count on first passed column.name
    # when lazy-loaded.  Otherwise, we run into issues with
    # counting records in the default_scope placed by the lazy_load
    # module.
    def count_records(params, columns=[])

      relation = @relation || get_relation(params)
      columns.each do |c|
        assoc, method = c[:name].split('__')
        relation = relation.includes(assoc.to_sym).references(assoc.to_sym) if method
      end

      @model.const_defined?(:LAZY_LOADED) ? relation.count(columns.first.name) :
        relation.count
    end

    ######################################################################
    # The following is a hack to get around Netzke's broken handling
    # of filtering on PostgreSQL enums columns.
    def predicates_for_and_conditions(conditions)
      return nil if conditions.empty?

      predicates = conditions.map do |q|
        q = HashWithIndifferentAccess.new(q)

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
      predicates[1..-1].inject(predicates.first){ |r,p| r.and(p)  }
    end

    def update_predecate_for_enum(table, op, value)
      col = Arel::Nodes::NamedFunction.new("CAST", [table.as("TEXT")])
      col.matches "%#{value}%"
    end
  end
end

class StringEnum < String
  include Delorean::Model
  def name
    self.to_s
  end
  def id
    self
  end
  delorean_instance_method :name
  delorean_instance_method :id

  def to_yaml(opts = {})
    YAML::quick_emit(nil, opts) do |out|
      out.scalar('stringEnum', self.to_s, :plain)
    end
  end

  def _dump _
    self.to_s
  end

  def self._load(v)
    new(v)
  end
end

YAML::add_domain_type("pennymac.com,2017-06-02", "stringEnum") do
  |type, val|
  StringEnum.new(val)
end

######################################################################

# Add pg_enum migration support -- FIXME: this doesn't belong here
module ActiveRecord
  module ConnectionAdapters
    class TableDefinition
      def pg_enum(*args)
        options = args.extract_options!
        column_names = args
        column_names.each { |name| column(name, name.to_s.pluralize, options) }
      end
    end
    module PostgreSQL
      module OID
        class Enum < Type::Value
          def type_cast_from_database(value)
            value && StringEnum.new(value)
          end
        end
      end
    end
  end
end

######################################################################

class ActiveRecord::Relation
  def mcfly_pt(pt, cls=nil)
    cls ||= self.klass
    tb = cls.table_name
    self.where("#{tb}.obsoleted_dt >= ? AND #{tb}.created_dt < ?", pt, pt)
  end
end

######################################################################

class ActiveRecord::Base
  class << self
    alias_method :old_joins, :joins

    def joins(*args)
      # when joins args are strings, checks to see if they're
      # associations attrs.  If so, convert them to symbols for joins
      # to work properly.
      new_args = args.map {|a|
        self.reflections.has_key?(a) ? a.to_sym : a
      }
      old_joins(*new_args)
    end
  end
end

args_hack = [[ActiveRecord::Relation, ActiveRecord::QueryMethods::WhereChain]] +
            [[Object, nil]]*10

Delorean::RUBY_WHITELIST.merge!(
  count:    [ActiveRecord::Relation],
  distinct: args_hack,
  group:    args_hack,
  joins:    args_hack,
  limit:    [ActiveRecord::Relation, Integer],
  not:      args_hack,
  order:    args_hack,
  pluck:    args_hack,
  select:   args_hack,
  where:    args_hack,
  mcfly_pt: [ActiveRecord::Relation,
             [Date, Time, ActiveSupport::TimeWithZone, String],
             [nil, Class]],
)

######################################################################

module Mcfly::Controller
  # define mcfly user to be Flowscape's current_user.
  def user_for_mcfly
    find_current_user rescue nil
  end
end
