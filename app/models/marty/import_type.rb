class Marty::ImportType < Marty::Base
  class ImportTypeValidator < ActiveModel::Validator
    def validate(entry)
      klass = entry.get_model_class

      if !klass.is_a?(Class) || !(klass < ActiveRecord::Base)
        entry.errors[:base] = "bad model name"
      else
        if entry.synonym_fields
          fields = entry.get_synonym_fields - klass.attribute_names -
            klass.reflect_on_all_associations.map(&:name).map(&:to_s)

          entry.errors[:base] = "unknown field(s) #{fields.join(',')}" unless
            fields.empty?
        end

        func = entry.cleaner_function
        entry.errors[:base] = "unknown class method #{func}" if
          func && !klass.respond_to?(func.to_sym)
      end

    end
  end

  attr_accessible :name, :model_name, :synonym_fields, :cleaner_function

  validates_presence_of :name, :model_name
  validates_uniqueness_of :name
  validates_with ImportTypeValidator
  has_many :import_synonyms

  def get_synonym_fields
    sf = self.synonym_fields || ""
    sf.gsub(" ", "").split(',')
  end

  def get_model_class
    model_name.constantize
  end

  def synonym_hash
    synh = import_synonyms.inject({}) { |h, is|
      h[is.synonym] = is.internal_name
      h
    }

    get_synonym_fields.inject({}) { |h, f|
      h[f] = synh
      h
    }
  end

end
