class Marty::Config < Marty::Base
  class ConfigValidator < ActiveModel::Validator
    def validate(entry)
      v = entry.value.to_json
      entry.errors[:base] = "bad JSON value" if !v
      v
    end
  end

  validates_presence_of :key, :value
  validates_uniqueness_of :key
  validates_with ConfigValidator


  delorean_fn :lookup, sig: 1 do
    |key|
    self[key]
  end

  def get_value
        self.value[0]
  end

  def self.[]=(key, value)
    entry = find_by_key(key)
    if !entry
      entry = self.new
      entry.key = key
    end
    entry.value = [value]
    entry.save!

    value
  end

  def self.[](key)
    entry = find_by_key(key)
    entry and entry.get_value
  end

  def self.del(key)
    entry = find_by_key(key)
    if entry
      result = entry.get_value
      entry.destroy
      result
    end
  end
end
