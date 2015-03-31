# ATTRIBUTION NOTE: This module has been mostly copied from the
# lazy_columns gem. The original code can be found at:
# https://github.com/jorgemanrubia/lazy_columns

module Marty
  module LazyColumnLoader
    extend ActiveSupport::Concern

    module ClassMethods
      def lazy_load(*columns)
        return unless table_exists?
        columns = columns.collect(&:to_s)
        exclude_columns_from_default_scope columns
        define_lazy_accessors_for columns

        # allow introspection of lazy-loaded column list
        const_set(:LAZY_LOADED, columns)
      end

    private
      def exclude_columns_from_default_scope(columns)
        default_scope {
          select((column_names - columns).map {
                   |column_name|
                   "#{table_name}.#{column_name}"
                 })
        }
      end

      def define_lazy_accessors_for(columns)
        columns.each { |column| define_lazy_accessor_for column }
      end

      def define_lazy_accessor_for(column)
        define_method column do
          unless has_attribute?(column)
            changes_before_reload = self.changes.clone
            self.reload
            changes_before_reload.each{
              |attribute_name, values|
              self.send("#{attribute_name}=", values[1])
            }
          end
          read_attribute column
        end
      end
    end
  end
end

if ActiveRecord::Base.respond_to?(:lazy_load)
  $stderr.puts "ERROR: Method `.lazy_load` already defined in " +
    "`ActiveRecord::Base`. This is incompatible with LazyColumnLoader " +
    "and the module will be disabled."
else
  ActiveRecord::Base.send :include, Marty::LazyColumnLoader
end
