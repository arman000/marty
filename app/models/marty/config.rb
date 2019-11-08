class Marty::Config < Marty::Base
  class ConfigValidator < ActiveModel::Validator
    def validate(entry)
      v = entry.get_value
      entry.errors[:base] << 'bad JSON value' if v.nil?
      v
    end
  end

  validates_presence_of :key, :value
  validates_uniqueness_of :key
  validates_with ConfigValidator

  delorean_fn :lookup, sig: 1 do |key|
    self[key]
  end

  def get_value
    value[0]
  end

  def set_value(v)
    self.value = [v]
  end

  def self.fetch(*args)
    unless (1..2).cover?(args.size)
      raise ArgumentError, 'wrong number of arguments '\
                           "(given #{args.size}, expected 1..2)"
    end

    entry = find_by_key(args[0])
    return entry.get_value if entry
    return args[1] if args.size > 1

    raise KeyError, "key not found: \"#{args[0]}\""
  end

  def self.[]=(key, value)
    entry = find_by_key(key)
    if !entry
      entry = new
      entry.key = key
    end
    entry.set_value(value)
    entry.save!

    value
  end

  def self.[](key)
    fetch(key, nil)
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
