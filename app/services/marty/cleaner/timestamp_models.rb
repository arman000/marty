module Marty
  module Cleaner
    module TimestampModels
      LOG_MESSAGE_TYPE = 'timestamp_model_cleaner'

      CLASSES_TO_CLEAN = [
        # Add these to monkey.rb in the format
        # ::YourApp::YourModelA,
        # ::YourApp::YourModelB
      ].freeze

      class << self
        def call(days_to_keep)
          CLASSES_TO_CLEAN.each do |klass|
            table_name = klass.table_name
            ::Marty::Cleaner::CleanAll.log(LOG_MESSAGE_TYPE, table_name) do
              klass.where(
                'updated_at <= ?', Time.zone.now - days_to_keep.days
              ).delete_all
            end
          end
        end
      end
    end
  end
end
