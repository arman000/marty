class Marty::Exclusion
  attr_reader :exclusion_data

  def initialize(hash_arr)
    @exclusion_data = hash_arr
  end

  def [](i)
    @exclusion_data[i]
  end

  def as_json
    arr = []
    @exclusion_data.each do |rec|
      rec.select { |key,val|
        arr.append({key => val})
      }
    end
    arr
  end

end

