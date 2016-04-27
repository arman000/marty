class LenientDataGrids < ActiveRecord::Migration
  include Marty::Migrations

  def change
    table_name = "marty_data_grids"

    add_column table_name,
               :lenient,
               :boolean,
               null: false,
               default: false

    return if Marty::DataGrid.unscoped.count == 0

    Mcfly.whodunnit = Marty::User.find_by_login("marty")

    disable_triggers(table_name) do
      lids = Marty::DataGrid.where(obsoleted_dt: 'infinity',
                                    name: [
                                      "Conv Units",
                                      "Conv LP",
                                      "OA Units",
                                      "OA High LTV Uncapped",
                                      "DURP Units",
                                      "Conv Secondary Financing",
                                      "OA With Sub",
                                      "Jumbo DTI/LTV",
                                      "DURP With Sub",
                                      "GL - FHA DTI/FICO/LTV",
                                    ]).pluck(:id).map(&:to_s).join(',')

      ActiveRecord::Base.connection.raw_connection.
        exec_params("update #{table_name} set lenient='T' where id IN (#{lids})", [])
    end
  end
end
