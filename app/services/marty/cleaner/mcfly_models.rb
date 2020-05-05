module Marty
  module Cleaner
    module McflyModels
      LOG_MESSAGE_TYPE = 'mcfly_model_cleaner'

      CLASSES_TO_CLEAN = [
        # Add these to monkey.rb in the format
        # ::YourApp::YourModelA,
        # ::YourApp::YourModelB
      ].freeze

      class << self
        def call(days_to_keep)
          CLASSES_TO_CLEAN.each do |klass|
            table_name = klass.table_name
            # Need to disable the McFly triggers first
            ::Marty::McflyHelper::DisableTriggers.call(table_name) do
              ::Marty::Cleaner::CleanAll.log(LOG_MESSAGE_TYPE, table_name) do
                klass.where(
                  'obsoleted_dt <= ?', Time.zone.now - days_to_keep.days
                ).delete_all
              end
            end
          end
        end
      end
    end
  end
end
