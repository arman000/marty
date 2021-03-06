class Marty::ImportType < Marty::Base
  class ImportTypeValidator < ActiveModel::Validator
    def validate(entry)
      klass = entry.get_model_class

      unless klass.is_a?(Class) && klass < ActiveRecord::Base
        entry.errors.add :base, 'bad model name'
        return
      end

      [
        entry.cleaner_function,
        entry.validation_function,
        entry.preprocess_function,
      ].each do |func|
        entry.errors.add(:base, "unknown class method #{func}") if
        func && !klass.respond_to?(func.to_sym)
      end
    end
  end

  before_validation do
    # Fix issue with blank strings in popup edit form or grid
    # being interpreted as a function
    self.cleaner_function = nil if cleaner_function.blank?
    self.validation_function = nil if validation_function.blank?
    self.preprocess_function = nil if preprocess_function.blank?
  end

  validates :name, :db_model_name, :role, presence: true
  validates :name, uniqueness: true
  validates_with ImportTypeValidator

  def get_model_class
    db_model_name.constantize if db_model_name
  end

  def allow_import?
    Mcfly.whodunnit && Mcfly.whodunnit.roles.include?(role)
  end
end
