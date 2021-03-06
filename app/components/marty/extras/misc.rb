module Marty::Extras::Misc
  MM_OPTIONS = {
    editor_config: {
      trigger_action: :all,
      xtype: :combo,
      store: (1..12).map { |x| [x, '%<x>02d' % { x: x }] },
      # FIXME: for some reason, with Netzke 0.8.2, the label show
      # up in the grid editor.  This hack seems to fix the
      # problem.  However, the label in the add-in-form now looks
      # weird.
      label_align: :top,
    },
    renderer: "function(v){return ('0' + v).slice (-2);}",
    # FIXME: a little bogus since this is computed statically.  lambda
    # didn't work.
    default_value: Time.zone.today.month
  }
  def self.numberfield_cfg(decimal_places)
    {
      format: '0.' + '0' * decimal_places,
      xtype: 'numbercolumn',
      editor_config: { hide_trigger: true,
                       decimal_precision: decimal_places },
      field_config: { decimal_precision: decimal_places,
                      xtype: :numberfield,
                      hide_trigger: true,
                      key_nav_enabled: false,
                      mouse_wheel_enabled: false }
    }
  end

  def sep
    { xtype: 'tbseparator' }
  end

  def icon_hack(name)
    # There's a Netzke bug whereby, using an icon name in a hash
    # doesn't generate a proper URL.
    "#{Netzke::Core.ext_uri}/../icons/#{name}.png"
  end
end
