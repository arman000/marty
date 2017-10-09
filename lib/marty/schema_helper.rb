class Marty::SchemaHelper
  include Delorean::Model
  delorean_fn :enum_is, sig: 2 do
    |var, value|
    {"properties"=> {var => { "enum"=> value}}}
  end
  delorean_fn :bool_is, sig: 2 do
    |var, value|
    {"properties"=> {var => { "type"=> "boolean", "enum"=> [value]}}}
  end

  delorean_fn :or, sig: [1, 20] do
    |*args|
    {"anyOf"=>args}
  end

  delorean_fn :and, sig: [1, 20] do
    |*args|
    {"allOf"=>args}
  end

  delorean_fn :not, sig: 1 do
    |arg|
    {"not"=>{"allOf"=>[arg]}}
  end

  # if conds is true, var_array columns we be required
  delorean_fn :required_if, sig: [2, 20] do
    |var_array, *conds_array|
    {"anyOf"=>[{"not"=>{"allOf"=> conds_array}},
               {"required"=>var_array}]}
  end

  # if dep_column is present, checks must pass
  delorean_fn :dep_check, sig: [2, 20] do
    |dep_column, *checks|
    {"dependencies"=> {dep_column =>
                       {"type"=>"object",
                        "allOf"=> checks}}}
  end

end
