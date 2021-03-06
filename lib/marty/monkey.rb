# Various monkey patches go here

######################################################################

require 'delorean_lang'

# Be able to access Enums from Delorean
class Delorean::BaseModule::BaseClass
  class << self
    alias_method :old_get_attr, :_get_attr

    def _get_attr(obj, attr, _e)
      if (Marty::Enum === obj ||
          ::Marty::EnumHelper.pg_enum?(klass: obj)) && !obj.respond_to?(attr)
        obj[attr]
      else
        old_get_attr(obj, attr, _e)
      end
    end
  end
end

######################################################################

# Patch Delorean to work with promises

class Delorean::BaseModule::NodeCall
  def initialize(_e, engine, node, params)
    super

    # If call has a promise_id (i.e. is from a promise) then that's
    # our parent.  Otherwise, we use its parent as our parent.
    params[:_parent_id] = _e[:_promise_id] || _e[:_parent_id]
    params[:_user_id]   = _e[:_user_id]    || Mcfly.whodunnit.try(:id)
  end

  # def log(msg)
  #   open('/tmp/dj.out', 'a') { |f| f.puts msg }
  # end

  # Monkey-patch '|' method for Delorean NodeCall to create promise
  # jobs and return promise proxy objects.
  def |(args)
    if args.is_a?(String)
      attr = args
      args = [attr]
    else
      raise 'bad arg to %' unless args.is_a?(Array)

      attr = nil
    end
    script, tag = engine.module_name, engine.sset.tag
    nn = node.is_a?(Class) ? node.name : node.to_s
    begin
      # make sure params is serialzable before starting a Job
      JSON.dump(params)
    rescue StandardError => e
      raise "non-serializable parameters: #{params} #{e}"
    end

    Marty::Promises::Delorean::Create.call(
      params: params,
      script: script,
      node_name: nn,
      attr: attr,
      args: args,
      tag: tag
    )
  end
end

class Delorean::Engine
  # FIXME: Marty::Event no longer exists, we should remove event at some point
  def background_eval(node, params, attrs, _event = {})
    raise 'background_eval bad params' unless params.is_a?(Hash)

    nc = Delorean::BaseModule::NodeCall.new({}, self, node, params)
    # start the background promise
    nc | attrs
  end
end

######################################################################

class Hash
  # define addition on hashes -- useful in Delorean code.
  def +(x)
    merge(x)
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

# FIXME: Move to Netzke
module Netzke
  module Basepack
    class ColumnConfig < AttrConfig
      alias old_set_defaults set_defaults

      def set_defaults
        old_set_defaults

        return set_defaults_combo if editor_config && editor_config[:xtype] == :combo

        return unless xtype == :checkcolumn
        # Use default value only if there is a boolean attribute with that name
        return unless @model_adapter.attr_type(name) == :boolean
        return if key?(:default_value)

        m = @model_adapter.model

        return self.default_value = false unless m.respond_to?(:column_defaults)

        self.default_value = @model_adapter.model.column_defaults[name] || false
      end

      def set_defaults_combo
        # Allow matching of the typed characters at any position in the values.
        editor_config[:any_match] = true unless editor_config.key?(:any_match)
      end
    end

    class FieldConfig < AttrConfig
      alias old_set_defaults set_defaults

      def set_defaults
        old_set_defaults

        return set_defaults_combo if xtype == :combo
      end

      def set_defaults_combo
        # Allow matching of the typed characters at any position in the values.
        self.any_match = true unless key?(:any_match)
      end
    end
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

        value = q['value']
        op = q['operator']

        attr_type = attr_type(attr)

        case attr_type
        when :datetime
          update_predecate_for_datetime(arel_table[method], op, value.to_date)
        when :string, :text, :citext
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

    def update_predecate_for_enum(table, _op, value)
      col = Arel::Nodes::NamedFunction.new('CAST', [table.as('TEXT')])
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
    cls ||= klass
    tb = cls.table_name
    where("#{tb}.obsoleted_dt >= ? AND #{tb}.created_dt < ?", pt, pt)
  end

  def attributes
    to_a.map(&:attributes)
  end
end

######################################################################

require 'marty/cache_adapters'

class ActiveRecord::Base
  class << self
    alias_method :old_joins, :joins

    def joins(*args)
      # when joins args are strings, checks to see if they're
      # associations attrs.  If so, convert them to symbols for joins
      # to work properly.
      new_args = args.map do |a|
        reflections.key?(a) ? a.to_sym : a
      end
      old_joins(*new_args)
    end
  end
end

ar_instances = [ActiveRecord::Relation, ActiveRecord::QueryMethods::WhereChain]

args_hack = Delorean::Ruby::Whitelists::Matchers::Arguments::ANYTHING

[
  [:distinct, args_hack],
  [:count,    []],
  [:find_by,  args_hack],
  [:first,    args_hack],
  [:group,    args_hack],
  [:joins,    args_hack],
  [:limit,    [Integer]],
  [:last,     [[Integer, nil]]],
  [:not,      args_hack],
  [:order,    args_hack],
  [:pluck,    args_hack],
  [:select,   args_hack],
  [:where,    args_hack],
  [:mcfly_pt, [[Date, Time, ActiveSupport::TimeWithZone, String], [nil, Class]]]
].each do |meth, args|
  ::Delorean::Ruby.whitelist.add_method meth do |method|
    ar_instances.each do |ar|
      method.called_on ar, with: args
    end
  end

  ::Delorean::Ruby.whitelist.add_class_method meth do |method|
    method.called_on ActiveRecord::Base, with: args
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
    to_h
  end
end

######################################################################

module Netzke
  module Core
    module DynamicAssets
      class << self
        def minify_js(js_string)
          if Rails.application.config.marty.uglify_assets
            # Doesn't fully support ES6 syntax
            return Uglifier.compile(js_string, harmony: true)
          end

          js_string.gsub(/\/\*\*[^*]*\*+(?:[^*\/][^*]*\*+)*\//, '') # strip docs
        end
      end
    end
  end
end

module Netzke
  module Core
    class ClientClassConfig
      # FIXME: move to Netzke
      # This fix removes ; in the end of JS code that is required by JS linters
      # And adds new line before closing bracket, so that if there is a comment
      # in the end of file, it won't break the code.
      def override_from_file(path)
        str = File.read(path)
        str.chomp!("\n")
        str.chomp!(';')
        %{#{class_name}.override(#{str}
);}
      end
    end
  end
end

require 'delayed_cron_job'
require_relative './delayed_job/scheduled_job_plugin.rb'
require_relative './delayed_job/queue_adapter.rb'

Delayed::Worker.plugins << Marty::DelayedJob::ScheduledJobPlugin

if ActiveJob::QueueAdapters::DelayedJobAdapter.respond_to?(:enqueue)
  ActiveJob::QueueAdapters::DelayedJobAdapter.extend(
    Marty::DelayedJob::QueueAdapter
  )
else
  ActiveJob::QueueAdapters::DelayedJobAdapter.include(
    Marty::DelayedJob::QueueAdapter
  )
end
