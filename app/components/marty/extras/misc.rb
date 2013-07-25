module Marty::Extras::Misc
  MM_OPTIONS = {
    editor: {
      trigger_action: :all,
      xtype: :combo,
      store: (1..12).map {|x| [x, "%02d" % x]},
      # FIXME: for some reason, with Netzke 0.8.2, the label show
      # up in the grid editor.  This hack seems to fix the
      # problem.  However, the label in the add-in-form now looks
      # weird.
      label_align: :top,
    },
    renderer: "function(v){return ('0' + v).slice (-2);}",
    # FIXME: a little bogus since this is computed statically.  lambda
    # didn't work.
    default_value: Date.today.month
  }
end
