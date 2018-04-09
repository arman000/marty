require 'delorean_lang'

class Gemini::Helper
  include Delorean::Model

  # Just for testing
  delorean_fn :sleep, sig: 1 do
    |seconds|
    Kernel.sleep seconds
  end

  # Just for testing
  delorean_fn :to_csv, sig: [1, 2] do
    |*args|

    # NOTE: can't use |data, config| due to delorean_fn weirdness.
    data, config = args

    Marty::DataExporter.to_csv(data, config)
  end

  # Just for testing
  delorean_fn :import_data, sig: [2, 3] do
    |import_type_name, data, col_sep|

    col_sep ||= "\t"

    imp_t = Marty::ImportType.find_by_name(import_type_name)

    raise "Insufficient permissions to run the data import" unless
      imp_t.allow_import?

    Marty::DataImporter.do_import_summary(imp_t.get_model_class,
                                          data,
                                          'infinity',
                                          imp_t.cleaner_function,
                                          imp_t.validation_function,
                                          col_sep,
                                          false)
  end

  delorean_fn :infinity_dt, sig: 1 do
    |pt|
    Mcfly.is_infinity pt
  end

  delorean_fn :testlog, sig: 2 do
    |str, data|
    10.times { Marty::Logger.info(str, data) }
    true
  end
  delorean_fn :testaction, sig: 2 do
    |str, id|
    File.open("/tmp/logaction.txt", "a") do |f|
      f.puts str % [id]
    end
  end


end
