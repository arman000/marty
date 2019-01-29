class Marty::SchemaHelper
  include Delorean::Model

  delorean_fn :enum_is, sig: 2 do |var, value|
    {"properties"=> {var => { "enum"=> value}}}
  end

  delorean_fn :bool_is, sig: 2 do |var, value|
    {"allOf"=>[{"required"=>[var]},
               {"properties"=> {var => { "type"=> "boolean", "enum"=> [value]}}}]}
  end

  delorean_fn :or, sig: [1, 20] do |*args|
    {"anyOf"=>args}
  end

  delorean_fn :and, sig: [1, 20] do |*args|
    {"allOf"=>args}
  end

  delorean_fn :not, sig: 1 do |arg|
    {"not"=>{"allOf"=>[arg]}}
  end

  # if conds is true, var_array columns we be required
  delorean_fn :disallow_if_conds, sig: [2, 20] do |var_array, *conds_array|
    {"anyOf"=>[{"not"=>{"allOf"=> conds_array}},
               {"properties"=> var_array.each_with_object({}) do |v, h|
                  h[v] = { "not" => {} }
                               end
               }]}
  end


  # if param is present, disallow cols
  delorean_fn :disallow_if_present, sig: [2, 20] do |dep_column, *var_array|
    dep_check(dep_column,
              {"properties"=> var_array.each_with_object({}) do |v, h|
                 h[v] = { "not" => {} }
                              end
              })
  end

  # if param is not present, disallow cols
  # note: small problem, probably not fixable:
  #  if this condition fails (i.e. dep_column is not present,
  #  but var(s) in var_array are are present)
  #  it will report both the required clause and the not clauses
  #  as failed.   so the caller will see a message that a
  #  required field is missing (which is not really a required field)
  delorean_fn :disallow_if_not_present, sig: [2, 20] do |dep_column, *var_array|
    { "anyOf" => [
        {"required" => [dep_column] },
        {"properties"=> var_array.each_with_object({}) do |v, h|
           h[v] = { "not" => {} }
                        end
        }]}
  end

  # if conds is true, var_array columns are not allowed
  delorean_fn :required_if, sig: [2, 20] do |var_array, *conds_array|
    {"anyOf"=>[{"not"=>{"allOf"=> conds_array}},
               {"required"=>var_array}]}
  end

  # if dep_column is present, checks must pass
  delorean_fn :dep_check, sig: [2, 20] do |dep_column, *checks|
    {"dependencies"=> {dep_column =>
                       {"type"=>"object",
                        "allOf"=> checks}}}
  end

end
