module Marty
  class DataGridUserView < DataGridView
    has_marty_permissions read: [:data_grid_editor, :admin, :dev]

    def configure(c)
      super

      c.attributes =
        [
          :name,
          :created_dt,
        ]
    end

    def default_bbar
      [:edit_grid]
    end

    def get_records(params)
      cur_perms = Mcfly.whodunnit.roles.map(&:name).map(&:to_sym)
      cur_perms_q = cur_perms.map { |p| "'#{p}'" }.join(',')
      rhs = "ARRAY[#{cur_perms_q}]"
      model.where("permissions->'view' ?| #{rhs} OR "\
                  "permissions->'edit_data' ?| #{rhs} OR "\
                  "permissions->'edit_all' ?| #{rhs}").scoping do
        super
      end
    end

    def self.get_edit_permission(permissions)
      cur_perms = Mcfly.whodunnit.roles.map(&:name)
      ['edit_all', 'edit_data', 'view'].detect do |p|
        permissions[p] - cur_perms != permissions[p]
      end
    end
  end
end

DataGridUserView = Marty::DataGridUserView
