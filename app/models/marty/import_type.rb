class Marty::ImportType < Marty::Base
  class ImportTypeValidator < ActiveModel::Validator
    def validate(entry)
      klass = entry.get_model_class

      unless klass.is_a?(Class) && klass < ActiveRecord::Base
        entry.errors.add :base, "bad model name"
        return
      end

      [
        entry.cleaner_function,
        entry.validation_function,
        entry.preprocess_function,
      ].each { |func|
        entry.errors.add(:base, "unknown class method #{func}") if
        func && !klass.respond_to?(func.to_sym)
      }
    end
  end

  before_validation do
    # Fix issue with blank strings in popup edit form or grid
    # being interpreted as a function
    self.cleaner_function = nil if self.cleaner_function.blank?
    self.validation_function = nil if self.validation_function.blank?
    self.preprocess_function = nil if self.preprocess_function.blank?
  end

  belongs_to :role

  validates_presence_of :name, :db_model_name, :role_id
  validates_uniqueness_of :name
  validates_with ImportTypeValidator

  def get_model_class
    db_model_name.constantize if db_model_name
  end

  def allow_import?
    Mcfly.whodunnit && Mcfly.whodunnit.roles.pluck(:id).include?(role_id)
  end

  delorean_fn :lookup, sig: 1 do
    |name|
    self.find_by_name(name)
  end

  delorean_fn :get_all, sig: 0 do
    self.all
  end
end
