module Marty
  class DataImporter
    class Error < StandardError
      attr_reader :lines

      def initialize(message, lines)
        msg = lines && lines.respond_to?(:join) ?
                "#{message} - lines: #{lines.join(',')}" : message

        super(msg)
        @lines = lines
      end
    end
    # perform cleaning and do_import and summarize its results
    def self.do_import_summary(klass,
                               data,
                               dt                  = 'infinity',
                               cleaner_function    = nil,
                               validation_function = nil,
                               col_sep             = "\t",
                               allow_dups          = false,
                               preprocess_function = nil
                              )

      recs = do_import(klass,
                       data,
                       dt,
                       cleaner_function,
                       validation_function,
                       col_sep,
                       allow_dups,
                       preprocess_function,
                      )

      recs.each_with_object(Hash.new(0)) do |(op, id), h|
        h[op] += 1
      end
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
                       preprocess_function = nil
                      )

      parsed = data.is_a?(Array) ? data :
        CSV.new(data, headers: true, col_sep: col_sep)

      # run preprocessor
      parsed = klass.send(preprocess_function.to_sym, parsed) if
        preprocess_function

      klass.transaction do
        cleaner_ids = cleaner_function ? klass.send(cleaner_function.to_sym) :
          []

        raise "bad cleaner function result" unless
          cleaner_ids.all? { |id| id.is_a?(Integer) }

        eline = 0

        begin
          res = parsed.each_with_index.map do |row, line|
            eline = line

            # skip lines which are all nil
            next :blank if row.to_hash.values.none?

            Marty::DataConversion.create_or_update(klass, row, dt)
          end
        rescue => exc
          # to find problems with the importer, comment out the rescue block
          raise Error.new(exc.to_s, [eline])
        end

        ids = {}
        # raise an error if record referenced more than once.
        res.each_with_index do |(op, id), line|
          raise Error
            .new("record referenced more than once", [ids[id], line]) if
            op != :blank && ids.member?(id) && !allow_dups

          ids[id] = line
        end

        begin
          # Validate affected rows if necessary
          klass.send(validation_function.to_sym, ids.keys) if
            validation_function
        rescue => exc
          raise Error.new(exc.to_s, [])
        end

        remainder_ids = cleaner_ids - ids.keys

        raise Error
          .new("Missing import data. " +
              "Please provide header line and at least one data line.", [1]) if
          ids.keys.compact.count == 0

        klass.delete(remainder_ids)
        res + remainder_ids.map { |id| [:clean, id] }
      end
    end
  end
end
