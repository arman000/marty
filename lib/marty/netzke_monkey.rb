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

        return unless xtype == :checkcolumn
        # Use default value only if there is a boolean attribute with that name
        return unless @model_adapter.attr_type(name) == :boolean
        return if key?(:default_value)

        m = @model_adapter.model

        return self.default_value = false unless m.respond_to?(:column_defaults)

        self.default_value = @model_adapter.model_column_defaults[name] || false
      end
    end
  end
end

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

    def update_predecate_for_enum(table, _op, value)
      col = Arel::Nodes::NamedFunction.new('CAST', [table.as('TEXT')])
      col.matches "%#{value}%"
    end
  end
end

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


########################################################
########################################################
#
# Get rid of code that accesses model directly.
# Replace with using model_adapter's methods

require 'netzke/basepack/data_adapters/abstract_adapter'
require 'netzke/basepack/data_adapters/active_record_adapter'

module Netzke::Basepack::DataAdapters
  class AbstractAdapter
    # Netzke sends all form config to the frontend
    # We don't wan't to serialize data adapter,
    # so we return a simple class name instead
    def to_json(options = {})
      self.class.name
    end

    def as_json(options = {})
      self.class.name
    end

    def find_record(id, options={})
      nil
    end

    def no_model?
      model.nil?
    end

    def model_column_defaults
      {}
    end

    def model_instance_methods
      raise NotImplementedError
    end

    def model_attribute_names
      raise NotImplementedError
    end

    def model_name
      model.name if model.respond_to? :name
    end

    def human_model_name
      model.model_name if model.respond_to? :model_name
      model.name if model.respond_to? :name
    end

    def new_model(params = nil)
      raise NotImplementedError
    end

    def save_record(record)
      raise NotImplementedError
    end

    def record_errors(record)
      raise NotImplementedError
    end

    def record_errors_hash(record)
      raise NotImplementedError
    end

    def destroy_record(record)
      raise NotImplementedError
    end
  end
end

module Netzke::Basepack::DataAdapters
  class ActiveRecordAdapter
    def model_instance_methods
      model.instance_methods
    end

    def model_column_defaults
      model.column_defaults
    end

    def model_attribute_names
      model.attribute_names
    end

    def new_model(params = nil)
      model.new(params)
    end

    def human_model_name
      model.model_name.human
    end

    def save_record(record)
      record.save
    end

    def record_errors(record)
      record.errors.to_a
    end

    def record_errors_hash(record)
      record.errors.to_h
    end

    def destroy_record(record)
      record.destroy
    end
  end
end

require 'netzke/basepack/attr_config'

module Netzke
  module Basepack
    # Base for FieldConfig and ColumnConfig
    class AttrConfig
      def responded_to_by_model?
        # if no model class is provided, assume the attribute is being responded to
        @model_adapter.no_model? ||
          !setter.nil? ||
          @model_adapter.model_instance_methods.include?(:"#{name}=") ||
          @model_adapter.model_attribute_names.include?(name)
      end
    end
  end
end

require 'netzke/basepack/columns'
module Netzke
  module Basepack
    module Columns
      def insert_primary_column(cols)
        primary_key = model_adapter.primary_key
        raise "Model #{model_adapter.model_name} does not have a primary column" if primary_key.blank?
        c = Netzke::Basepack::ColumnConfig.new(model_adapter.primary_key, model_adapter)
        c.merge_attribute(attribute_overrides[c.name.to_sym]) if attribute_overrides.has_key?(c.name.to_sym)
        augment_column_config(c)
        cols.insert(0, c)
      end
    end
  end
end

require 'netzke/form/services'

module Netzke
  module Form
    module Services
      # Creates/updates a record from hash
      def create_or_update_record(hsh)
        hsh.merge!(config[:strong_values]) if config[:strong_values]

        # only pick the record specified in the params if it was not provided in the configuration
        @record ||= model_adapter.find_record hsh.delete(model_adapter.primary_key)

        #model.find(:first, :conditions => model.primary_key => hsh.delete(model.primary_key)})
        success = true

        @record = model_adapter.new_model if @record.nil?

        hsh.each_pair do |k,v|
          model_adapter.set_record_value_for_attribute(@record, fields[k.to_sym].nil? ? {:name => k} : fields[k.to_sym], v)
        end

        # did we have complete success?
        success && model_adapter.save_record(@record)
      end

      # Builds the form errors
      def build_form_errors(record)
        form_errors = {}
        foreign_keys = model_adapter.hash_fk_model
        model_adapter.record_errors_hash(record).map{ |field, error|
          # some ORM return an array for error
          error = error.join ', ' if error.kind_of? Array
          # Get the correct field name for the errors on foreign keys
          if foreign_keys.has_key?(field)
            fields.each do |k, v|
              # Hack to stop to_nifty_json from camalizing model__field
              field = k.to_s.gsub('__', '____') if k.to_s.split('__').first == foreign_keys[field].to_s
            end
          end
          form_errors[field] ||= []
          form_errors[field] << error
        }
        form_errors
      end

    end
  end
end

require 'netzke/form/base'

module Netzke
  module Form
    class Base
      def model_adapter
        return config.model_adapter if config.model_adapter
        @model_adapter ||= Netzke::Basepack::DataAdapters::AbstractAdapter.adapter_class(model).new(model)
      end
    end
  end
end

require 'netzke/grid/base'

module Netzke
  module Grid
    # Child components for Grid and Tree
    class Base
      component :add_window do |c|
        configure_form_window(c)
        c.title = I18n.t('netzke.grid.base.add_record', model: model_adapter.human_model_name)
        c.items = [:add_form]
        c.form_config.model_adapter = model_adapter
        c.form_config.record = model_adapter.new_model(columns_default_values)
        c.excluded = !allowed_to?(:create)
      end

      component :edit_window do |c|
        configure_form_window(c)
        c.title = I18n.t('netzke.grid.base.edit_record', model: model_adapter.human_model_name)
        c.items = [:edit_form]
        c.form_config.model_adapter = model_adapter
        c.excluded = !allowed_to?(:update)
      end

      component :multiedit_window do |c|
        configure_form_window(c)
        c.title = I18n.t('netzke.grid.base.edit_records', models: model_adapter.human_model_name.pluralize)
        c.items = [:multiedit_form]
        c.form_config.model_adapter = model_adapter
        c.excluded = !allowed_to?(:update)
      end

      component :search_window do |c|
        c.klass = Basepack::SearchWindow
        c.model = config.model
        c.fields = attributes_for_search
      end

      def destroy(ids)
        out = {}

        ids.each do |id|
          record = model_adapter.find_record(id, scope: config[:scope])
          next if record.nil?

          if model_adapter.destroy_record(record)
            out[id] = "ok"
          else
            out[id] = { error: model_adapter.record_errors(record) }
          end
        end

        out
      end

      def update_record(record, attrs)
        attrs.each_pair do |k,v|
          attr = final_columns_hash[k.to_sym]
          next if attr.nil?
          model_adapter.set_record_value_for_attribute(record, attr, v)
        end

        strong_attrs = config[:strong_values] || {}

        strong_attrs.each_pair do |k,v|
          model_adapter.set_record_value_for_attribute(record, {name: k.to_s}, v)
        end

        if model_adapter.save_record(record)
          {record: model_adapter.record_to_array(record, final_columns)}
        else
          {error: model_adapter.record_errors(record)}
        end
      end
    end
  end
end

require 'netzke/grid/configuration'

module Netzke
  module Grid
    module Configuration # WTF: naming it Config causes troubles in 1.9.3
      def configure_client(c)
        super
        c.title ||= model_adapter.model_name.pluralize
        c.columns = {items: js_columns}
        c.columns_order = columns_order
        c.pri = model_adapter.primary_key
        if c.default_filters
          populate_columns_with_filters(c)
        end
      end

      def validate_config(c)
        raise ArgumentError, "Grid requires a model" if model_adapter.no_model?

        c.editing = :in_form if c.editing.nil?

        c.edits_in_form = [:both, :in_form].include?(c.editing)
        c.edits_inline = [:both, :inline].include?(c.editing)

        if c.paging.nil?
          c.paging = c.edits_inline ? :pagination : :buffered
        end

        if c.paging == :buffered && c.edits_inline
          raise ArgumentError, "Buffered grid cannot have inline editing"
        end

        c.tools = tools
        c.bbar = bbar
        c.context_menu = context_menu

        super
      end
    end
  end
end

