require 'csv'

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

    # To replace do_import_summary
    # _proc input params will be read in as a lambda
    # EX: cleaner_proc: -> { do_something }
    #     validation_proc: ->(ids) { do_something }
    #     preprocess_proc: ->(data) { do_something }
    def self.call(klass,
                  data,
                  dt: 'infinity',
                  cleaner_proc: nil,
                  validation_proc: nil,
                  col_sep: "\t",
                  allow_dups: false,
                  preprocess_proc: nil,
                  suppress_empty_data_error: false
                 )

      parsed = data.is_a?(Array) ? data :
        ::CSV.new(data, headers: true, col_sep: col_sep)

      # run preprocessor
      parsed = preprocess_proc.call(parsed) if preprocess_proc

      recs = klass.transaction do
        cleaner_ids = cleaner_proc ? call_cleaner_proc(cleaner_proc) : []

        res = create_or_update_parsed_rows(klass, parsed, dt)

        ids = duplicate_record_check(res, allow_dups)

        call_validation_proc(validation_proc, ids) if validation_proc

        remainder_ids = cleaner_ids - ids.keys

        raise_empty_data_error(ids) unless suppress_empty_data_error

        purge_and_return(klass, res, remainder_ids)
      end

      recs.each_with_object(::Hash.new(0)) do |(op, _id), h|
        h[op] += 1
      end
    end

    # FIXME: This function is depricated and
    # should be removed in the future
    # perform cleaning and do_import and summarize its results
    def self.do_import_summary(klass,
                               data,
                               dt                  = 'infinity',
                               cleaner_function    = nil,
                               validation_function = nil,
                               col_sep             = "\t",
                               allow_dups          = false,
                               preprocess_function = nil,
                               suppress_empty_data_error = false
                              )

      recs = do_import(klass,
                       data,
                       dt,
                       cleaner_function,
                       validation_function,
                       col_sep,
                       allow_dups,
                       preprocess_function,
                       suppress_empty_data_error,
                      )

      recs.each_with_object(::Hash.new(0)) do |(op, _id), h|
        h[op] += 1
      end
    end

    # FIXME: This function is depricated and
    # should be removed in the future
    # Given a Mcfly klass and CSV data, import data into the database
    # and report on affected rows. Result is an array of tuples.
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
                       preprocess_function = nil,
                       suppress_empty_data_error = false
                      )

      parsed = data.is_a?(Array) ? data :
        ::CSV.new(data, headers: true, col_sep: col_sep)

      # run preprocessor
      parsed = klass.send(preprocess_function.to_sym, parsed) if
        preprocess_function

      klass.transaction do
        cleaner_ids = cleaner_function ? klass.send(cleaner_function.to_sym) :
          []

        raise 'bad cleaner function result' unless
          cleaner_ids.all? { |id| id.is_a?(Integer) }

        res = create_or_update_parsed_rows(klass, parsed, dt)

        ids = duplicate_record_check(res, allow_dups)

        begin
          # Validate affected rows if necessary
          klass.send(validation_function.to_sym, ids.keys) if
            validation_function
        rescue StandardError => e
          raise Error.new(e.to_s, [])
        end

        remainder_ids = cleaner_ids - ids.keys

        raise_empty_data_error(ids) unless suppress_empty_data_error

        purge_and_return(klass, res, remainder_ids)
      end
    end

    class << self
      private

      def call_cleaner_proc(cleaner_proc)
        cleaner_ids = cleaner_proc.call

        raise 'bad cleaner proc result' unless
          cleaner_ids.all? { |id| id.is_a?(Integer) }

        cleaner_ids
      end

      def create_or_update_parsed_rows(klass, parsed, dt)
        parsed.each_with_index.map do |row, line|
          begin
            # skip lines which are all nil
            next :blank if row.to_hash.values.none?

            Marty::DataConversion.create_or_update(klass, row, dt)
          rescue StandardError => e
            # to find problems with the importer, comment out the rescue block
            raise Error.new(e.to_s, [line])
          end
        end
      end

      def duplicate_record_check(res, allow_dups)
        ids = {}
        # raise an error if record referenced more than once.
        res.each_with_index do |(op, id), line|
          raise Error.
            new('record referenced more than once', [ids[id], line]) if
            op != :blank && ids.member?(id) && !allow_dups

          ids[id] = line
        end

        ids
      end

      def call_validation_proc(validation_proc, ids)
        # Validate affected rows if necessary
        validation_proc.call(ids.keys)
      rescue StandardError => e
        raise Error.new(e.to_s, [])
      end

      def raise_empty_data_error(ids)
        raise Error.
          new('Missing import data. ' +
              'Please provide header line and at least one data line.', [1]) if
          ids.keys.compact.count == 0
      end

      def purge_and_return(klass, res, remainder_ids)
        klass.delete(remainder_ids)
        res + remainder_ids.map { |id| [:clean, id] }
      end
    end
  end
end
