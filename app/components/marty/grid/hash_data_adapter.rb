module Marty
  class Grid::HashDataAdapter < Netzke::Basepack::DataAdapters::AbstractAdapter
    def self.for_class?(member_class)
      return false if member_class.nil?

      member_class <= self
    end

    def model_instance_methods
      []
    end

    def virtual_attribute?(_attr)
      false
    end

    def model_name
      raise NotImplementedError
    end

    def human_model_name
      raise NotImplementedError
    end

    def record_to_array(r, columns)
      columns.map do |c|
        r[c.name.to_s]
      end
    end

    def record_to_hash(r, attrs)
      {}.tap do |res|
        attrs.each do |a|
          next if a[:included] == false

          res[a[:name].to_sym] = record_value_for_attribute(r, a, a[:nested_attribute])
        end
      end
    end

    def record_value_for_attribute(record, attr, _through_association = false)
      record[attr[:name]] || record.with_indifferent_access[attr[:name]]
    end

    def set_record_value_for_attribute(record, attr, value)
      return if attr[:name] == 'association_values'

      record[attr[:name]] = value
    end

    def record_errors(record)
      record['errors']&.values&.sum
    end

    def record_errors_hash(record)
      record['errors']
    end

    def errors_array(record)
      record['errors']&.values&.sum
    end

    def hash_fk_model
      {}
    end

    def new_model(_params = nil)
      {}
    end

    def new_record
      {}
    end

    # Array of attributes
    def model_attribute_names
      raise NotImplementedError
    end

    # Finds a record by id, return hash
    def find_record(id, options = {})
      raise NotImplementedError
    end

    # Finds array of hashes
    def get_records(params, columns)
      raise NotImplementedError
    end

    # Receives a hash with record attributes, returns true/false
    # If error, make sure to add 'errors' hash to record, for example:
    # { "errors" => { "firstname" => ["Firstname can't be blank"] }
    def save_record(record)
      raise NotImplementedError
    end

    # Receives a hash with record attributes, returns true/false
    # If error, make sure to add 'errors' hash to record, for example:
    # { "errors" => { "firstname" => ["Firstname can't be blank"] }
    def destroy_record(record)
      raise NotImplementedError
    end
  end
end
