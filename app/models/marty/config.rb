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

<<<<<<< 8ca2019c045758a2f85d8148b1d3aac1f2847fde
=======

>>>>>>> adds rspec for view writer
  delorean_fn :lookup, sig: 1 do
    |key|
    self[key]
  end

  def get_value
<<<<<<< 8ca2019c045758a2f85d8148b1d3aac1f2847fde
    self.value[0]
=======
        self.value[0]
>>>>>>> adds rspec for view writer
  end

  def set_value(v)
    self.value = [v]
  end

  def self.[]=(key, value)
    entry = find_by_key(key)
    if !entry
      entry = self.new
      entry.key = key
    end
    entry.set_value(value)
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
