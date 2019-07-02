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
      c.editing = :inline
    end

    def default_bbar
      [:edit_grid]
    end

    def get_records(params)
      cur_perms = Mcfly.whodunnit.roles.map(&:to_sym)
      model.where("permissions->'view'      ?| ARRAY[:roles] OR "\
                  "permissions->'edit_data' ?| ARRAY[:roles] OR "\
                  "permissions->'edit_all'  ?| ARRAY[:roles]",
                  roles: cur_perms).scoping do
        super
      end
    end

    def self.get_edit_permission(permissions)
      cur_perms = current_user_roles.map(&:to_s)
      ['edit_all', 'edit_data', 'view'].detect do |p|
        permissions[p] - cur_perms != permissions[p]
      end
    end
  end
end

DataGridUserView = Marty::DataGridUserView
