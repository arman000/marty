module Marty
  class DataGridUserView < DataGridView
    # permissions are handled by #get_records and #get_edit_permissions
    has_marty_permissions read: :any,
                        update: :any

    def configure(c)
      super

      c.attributes =
        [
          :name,
          :created_dt,
        ]
      c.title = I18n.t('data_grid_user_view')
      c.editing = :in_form
    end

    client_class do |c|
      c.do_edit_in_form = l(<<~JS)
         function(record) {
            var sel = this.getSelectionModel().getSelection()[0];
            var record_id = sel && sel.getId();
            if (!record_id) return;
            this.server.editGrid({record_id: record_id});
         }
      JS
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
