class Marty::ScriptLogGrid < Marty::CmGridPanel
  def configure(c)
    super

    c.title = I18n.t('script_log.title', default: "Script Log")
    c.model = "Marty::Script"

    # Used to select Scripts whose version is either not DEV or who
    # have an associated dscript record.
    sel = "(SELECT COUNT(*) FROM #{Marty::Dscript.table_name} " +
      "WHERE script_id = ?) > 0"

    c.scope = ["group_id = ? AND (version <> ? OR #{sel})",
               c[:group_id],
               Marty::Script::DEV_VERSION,
               c[:group_id],
              ]
    c.prohibit_update = true
    c.prohibit_delete = true
    c.prohibit_create = true
    c.prohibit_read   = !self.class.has_any_perm?

    c.columns ||= [:version, :last_update, :user__name, :log_message]
    c.data_store.sorters = {property: :version, direction: 'DESC'}
  end

  def default_bbar; [] end
  def default_context_menu; [] end

  column :version do |c|
    c.width = 60
    c.text = I18n.t("script_log.version")
  end

  # need to provide attr_type for formatting to work
  column :last_update do |c|
    c.format = "Y-m-d H:i"
    c.getter = lambda { |r|
      if !r.isdev?
        r.created_dt
      else
        ds = r.group_dscript
        ds && ds.updated_at
      end
    }
    c.attr_type = :datetime
    c.text = I18n.t("script_log.last_update")
  end

  column :user__name do |c|
    c.flex = 1
    c.text = I18n.t("script_log.user_name")
    c.getter = lambda { |r|
      if r.isdev?
        ds = r.group_dscript
        ds && ds.user.name
      else
        r.user.name
      end
    }
  end

  column :log_message do |c|
    c.flex = 1
    c.text = I18n.t("script_log.log_message")
    c.getter = lambda { |r|
      r.isdev? ? "-" : r.logmsg
    }
    c.flex = 2
  end
end

ScriptLogGrid = Marty::ScriptLogGrid
