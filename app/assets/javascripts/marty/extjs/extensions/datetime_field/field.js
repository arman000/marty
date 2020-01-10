/*
 * File: DateTimeField.js
 *
 * This file requires use of the Ext JS library, under independent license.
 * This is part of the UX for DateTimeField developed by Guilherme Portela
 */
Ext.define("Ext.ux.DateTimeField", {
  extend: "Ext.form.field.Date",
  alias: "widget.datetimefield",
  requires: ["Ext.ux.DateTimePicker"],

  //<locale>
  /**
   * @cfg {String} format
   * The default date format string which can be overriden for localization support. The format must be valid
   * according to {@link Ext.Date#parse}.
   */
  format: "m/d/Y H:i",
  //</locale>
  /**
   * @cfg {String} altFormats
   * Multiple date formats separated by "|" to try when parsing a user input value and it does not match the defined
   * format.
   */
  altFormats: "m/d/Y H:i:s|c",
  width: 270,

  collapseIf(e) {
    const me = this,
      picker = me.picker;

    if (picker.timePicker && !e.within(picker.timePicker.el, false, true)) {
      me.callParent([e]);
    }
  },

  createPicker() {
    const me = this,
      parentPicker = this.callParent(),
      parentConfig = Ext.clone(parentPicker.initialConfig),
      initialConfig = Ext.clone(me.initialConfig),
      excludes = ["renderTo", "width", "height", "bind", "reference"];

    // Avoiding duplicate ids error
    parentPicker.destroy();

    for (let i = 0; i < excludes.length; i++) {
      if (initialConfig[excludes[i]] !== undefined) {
        delete initialConfig[excludes[i]];
      }
    }

    return Ext.create(
      "Ext.ux.DateTimePicker",
      Ext.merge(initialConfig, parentConfig)
    );
  },

  getErrors(value) {
    value =
      arguments.length > 0
        ? value
        : this.formatDate(this.processRawValue(this.getRawValue()));

    const me = this,
      format = Ext.String.format,
      errors = me.superclass.superclass.getErrors.apply(this, arguments),
      disabledDays = me.disabledDays,
      disabledDatesRE = me.disabledDatesRE,
      minValue = me.minValue,
      maxValue = me.maxValue,
      len = disabledDays ? disabledDays.length : 0;

    let i = 0,
      day;

    if (value === null || value.length < 1) {
      // if it's blank and textfield didn't flag it then it's valid
      return errors;
    }

    const svalue = value;
    value = me.parseDate(value);
    if (!value) {
      errors.push(
        format(me.invalidText, svalue, Ext.Date.unescapeFormat(me.format))
      );
      return errors;
    }

    const time = value.getTime();
    if (minValue && time < minValue.getTime()) {
      errors.push(format(me.minText, me.formatDate(minValue)));
    }

    if (maxValue && time > maxValue.getTime()) {
      errors.push(format(me.maxText, me.formatDate(maxValue)));
    }

    if (disabledDays) {
      day = value.getDay();

      for (; i < len; i++) {
        if (day === disabledDays[i]) {
          errors.push(me.disabledDaysText);
          break;
        }
      }
    }

    const fvalue = me.formatDate(value);
    if (disabledDatesRE && disabledDatesRE.test(fvalue)) {
      errors.push(format(me.disabledDatesText, fvalue));
    }

    return errors;
  },

  getRefItems() {
    const me = this,
      result = me.callParent();

    if (me.picker && me.picker.timePicker) {
      result.push(me.picker.timePicker);
    }

    return result;
  },

  onExpand() {
    const me = this;

    me.callParent();
    const timePicker = me.picker && me.picker.timePicker;

    if (timePicker) {
      me.picker.alignTimePicker();
    }
  }
});
