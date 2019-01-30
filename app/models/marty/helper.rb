class Marty::Helper
  include Delorean::Model

  delorean_fn :sleep, sig: 1 do
    |seconds|
    Kernel.sleep seconds
  end

  delorean_fn :range_step, sig: 3 do
    |rstart, rend, step|
    (rstart..rend).step(step).to_a
  end

  delorean_fn :my_ip, sig:0 do
    Marty::Diagnostic::Node.my_ip
  end

  delorean_fn :git, sig:0 do
    [my_ip, ENV['DELAYED_VER']]
  end

  delorean_fn :infinity_dt, sig: 1 do |pt|
    Mcfly.is_infinity pt
  end

  delorean_fn :constantize, sig: 1 do |class_name|
    raise 'bad class_name' unless class_name.is_a?(String)
    class_name.constantize
  end

  delorean_fn :get_column_types, sig: 1 do |klass|
    Marty::DataConversion.col_types(klass)
  end

  delorean_fn :parse_csv_to_hash, sig: 3 do |txt, comma_sep, types|
    txt ||= ""
    headers, *rows = CSV.parse(txt.strip,
                               headers: true,
                               col_sep: (comma_sep ? "," : "\t")).to_a
    rows.map do |row|
      headers.zip(row).each_with_object({}) do |(h, v), res|
        res[h] = v.blank? ? nil :
                   Marty::DataConversion.convert(v, (types[h] || "text").to_sym)
      end
    end
  end

  delorean_fn :to_csv, sig: [1, 2] do |*args|
    # NOTE: can't use |data, config| due to delorean_fn weirdness.
    data, config = args

    Marty::DataExporter.to_csv(data, config)
  end
end
