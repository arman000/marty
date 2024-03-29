module Marty
  class DataGridView
    class SaveGrid
      class GridError < StandardError
        attr_reader :data, :id
        def initialize(msg, data, id)
          @msg = msg
          @data = data
          @id = id
        end

        def message
          "save_grid: #{@msg}"
        end
      end

      def self.call(params, dg, user_perm)
        data = params['data']

        raise GridError.new('entered with view permissions', data, rec_id) if
          user_perm == 'view'

        data_as_array_raw = data.map(&:values)

        vcnt = dg.metadata.count { |md| md['dir'] == 'v' }
        hcnt = dg.metadata.count { |md| md['dir'] == 'h' }

        cur_data_dim = [dg.data.length, dg.data[0].length]
        exported = dg.export.lines
        sep = exported.each_with_index.detect { |l, _i| /\A\s*\z/.match(l) }.last

        # Remove empty comment cells from h_rows
        data_as_array = data_as_array_raw.each_with_index.map do |row, index|
          next row if index >= hcnt

          row[0...-1]
        end

        new_data = data_as_array.map do |line|
          line.join("\t") + "\r\n"
        end.compact

        new_data_dim = [data_as_array.count - hcnt,
                        data_as_array[0].count - vcnt]

        if cur_data_dim != new_data_dim && user_perm != 'edit_all'
          raise GridError.new('grid modification not allowed', data_as_array,
                              rec_id)
        end

        data_only = data_as_array[hcnt..-1].map do |a|
          a[vcnt..-2]
        end

        chks = Marty::DataGrid::Constraint.parse(dg.data_type, dg.constraint)
        probs = Marty::DataGrid::Constraint.check_data(dg.data_type, data_only,
                                                       chks, cvt: true)

        return { 'problem_array' => probs } if probs.present?

        to_import = (exported[0..sep] + new_data).join
        dg.update_from_import(dg.name, to_import)
        false
      rescue GridError => e
        Marty::Logger.error(e.message, rec_id: e.id,
                            data: e.data,
                            perm: user_perm)
        { 'error_message' => e.message }
      rescue StandardError => e
        { 'error_message' => e.message }
      end
    end
  end
end
