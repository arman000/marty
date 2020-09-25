module Marty
  class DataGrid
    module UpdateAllToStrictNullMode
      def self.call
        Marty::DataGrid.transaction do
          dgs = Marty::DataGrid.where(
            obsoleted_dt: 'infinity',
            strict_null_mode: false
          )

          dgs.each do |dg|
            # rubocop:disable Rails/SkipsModelValidations
            dg.update_attribute(:strict_null_mode, true)
            # rubocop:enable Rails/SkipsModelValidations
          end

          dgs.size
        end
      end
    end
  end
end
