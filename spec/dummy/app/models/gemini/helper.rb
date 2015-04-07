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
    |import_type, data, col_sep|

    col_sep ||= "\t"

    raise "Insufficient permissions to run the data import" unless
      import_type.allow_import?

    Marty::DataImporter.do_import_summary(import_type.get_model_class,
                                          data,
                                          'infinity',
                                          import_type.cleaner_function,
                                          import_type.validation_function,
                                          col_sep,
                                          false)
  end
end
