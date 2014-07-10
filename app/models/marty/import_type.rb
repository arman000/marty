class Marty::ImportType < Marty::Base
  class ImportTypeValidator < ActiveModel::Validator
    def validate(entry)
      klass = entry.get_model_class

      unless klass.is_a?(Class) && klass < ActiveRecord::Base
        entry.errors[:base] = "bad model name"
        return
      end

      [entry.cleaner_function, entry.validation_function].each { |func|
        entry.errors[:base] = "unknown class method #{func}" if
        func && !klass.respond_to?(func.to_sym)
      }
    end
  end

  attr_accessible :name,
  :model_name,
  :cleaner_function,
  :validation_function

  validates_presence_of :name, :model_name
  validates_uniqueness_of :name
  validates_with ImportTypeValidator

  def get_model_class
    model_name.constantize
  end

  delorean_fn :lookup, sig: 1 do
    |name|
    self.find_by_name(name)
  end

  delorean_fn :get_all, sig: 0 do
    self.all
  end
end
