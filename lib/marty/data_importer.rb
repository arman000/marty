require 'csv'

module Marty
  class DataImporterError < StandardError
    attr_reader :lines

    def initialize(message, lines)
      msg = lines && lines.respond_to?(:join) ?
      "#{message} - lines: #{lines.join(',')}" : message

      super(msg)
      @lines = lines
    end
  end

  class DataImporter
    # perform cleaning and do_import and summarize its results
    def self.do_import_summary(klass,
                               data,
                               dt                  = 'infinity',
                               cleaner_function    = nil,
                               validation_function = nil,
                               col_sep             = "\t",
                               allow_dups          = false
                               )

      recs = self.do_import(klass,
                            data,
                            dt,
                            cleaner_function,
                            validation_function,
                            col_sep,
                            allow_dups,
                            )

      recs.each_with_object(Hash.new(0)) {|(op, id), h|
        h[op] += 1
      }
    end

    # Given a Mcfly klass and CSV data, import data into the database
    # and report on affected rows.  Result is an array of tuples.
    # Each tuple is associated with one data row and looks like [tag,
    # id].  Tag is one of :same, :update, :create and "id" is the id
    # of the affected row.
    def self.do_import(klass,
                       data,
                       dt                  = 'infinity',
                       cleaner_function    = nil,
                       validation_function = nil,
                       col_sep             = "\t",
                       allow_dups          = false,
                       key_attrs           = nil
                       )

      parsed = data.is_a?(Array) ? data :
        CSV.new(data, headers: true, col_sep: col_sep)

      klass.transaction do
        cleaner_ids = cleaner_function ? klass.send(cleaner_function.to_sym) :
          []

        raise "bad cleaner function result" unless
          cleaner_ids.all? {|id| id.is_a?(Fixnum) }

        row_proc = nil
        eline = 0

        begin
          res = parsed.each_with_index.map { |row, line|
            eline = line

            row_proc ||= Marty::DataRowProcessor.
            new(klass,
                row.respond_to?(:headers) ? row.headers : row.keys,
                dt,
                key_attrs,
                )
            # skip lines which are all nil
            next :blank if row.to_hash.values.none?

            row_proc.create_or_update(row)
          }
        rescue => exc
          # to find problems with the importer, comment out the rescue block
          raise Marty::DataImporterError.new(exc.to_s, [eline])
        end

        ids = {}

        # raise an error if record referenced more than once.
        res.each_with_index do
          |(op, id), line|
          raise Marty::DataImporterError.
            new("record referenced more than once", [ids[id], line]) if
            op != :blank && ids.member?(id) && !allow_dups

          ids[id] = line
        end

        begin
          # Validate affected rows if necessary
          klass.send(validation_function.to_sym, ids.keys) if
            validation_function
        rescue => exc
          raise Marty::DataImporterError.new(exc.to_s, [])
        end

        remainder_ids = cleaner_ids - ids.keys

        raise Marty::DataImporterError.
          new("Missing import data. " +
              "Please provide header line and at least one data line.", [1]) if
          ids.keys.compact.count == 0

        klass.delete(remainder_ids)
        res + remainder_ids.map {|id| [:clean, id]}
      end
    end
  end
end
