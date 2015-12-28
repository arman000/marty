class Marty::Config < Marty::Base
  class ConfigValidator < ActiveModel::Validator
    def validate(entry)
      v = entry.get_value
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
    begin
      self.value["value"]
    rescue
    end
  end

  def self.[]=(key, value)
    entry = find_by_key(key)
    if !entry
      entry = self.new
      entry.key = key
    end
    value_parsed = ActiveSupport::JSON.encode({ "value" => value })
    entry.value = value_parsed
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
