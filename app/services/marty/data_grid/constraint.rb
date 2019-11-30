module Marty
  class DataGrid
    class Constraint
      def self.parse(data_type, constraint)
        return [] unless constraint

        dt = DataGrid.convert_data_type(data_type)
        if /[><]/.match?(constraint)
          raise "range constraint not allowed for type #{dt}" unless
            ['integer', 'float'].include?(dt)

          pgr = Marty::Util.human_to_pg_range(constraint)
          r = DataGrid.parse_range(pgr)
          [r[0, 2], r[2..-1].reverse]
        else
          raw_vals = constraint.split('|')
          return unless raw_vals.present?
          raise 'list constraint not allowed for type Float' if dt == 'float'

          pt = 'infinity'
          vals = raw_vals.map do |v|
            DataGrid.parse_fvalue(pt, v, data_type, dt)
          end
          [[:in?, vals.flatten]]
        end
      end

      def self.real_type(data_type)
        types = case data_type
                when nil
                  [DEFAULT_DATA_TYPE.capitalize.constantize]
                when 'string', 'integer', 'float'
                  [data_type.capitalize.constantize]
                when 'boolean'
                  [TrueClass, FalseClass]
                else
                  [data_type]
                end
        types << Integer if types.include?(Float)
      end

      # if check_data is called from validation, data has already been converted
      # if called directly from DataGridView, it is still array of array of
      # string.
      def self.check_data(data_type, data, chks, cvt: false)
        dt = Marty::DataGrid.convert_data_type(data_type)
        klass = dt.class == Class ? dt : DataGrid.maybe_get_klass(dt)
        rt = real_type(data_type) # get real type for string, trueclass etc
        res = []
        pt = 'infinity'
        (0...data.first.length).each do |x|
          (0...data.length).each do |y|
            data_v = data[y][x]
            cvt_val = nil
            err = nil
            begin
              cvt_val = cvt && !data_v.class.in?(rt) ?
                          DataGrid.parse_fvalue(pt, data_v, dt, klass).first :
                          data_v
            rescue StandardError => e
              err = e.message
            end
            next res << [:type, x, y] if err

            res << [:constraint, x, y] unless
              chks.map { |op, chk_val| cvt_val.send(op, chk_val) }.all? { |v| v }
          end
        end
        res
      end
    end
  end
end
