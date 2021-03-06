Ext.define("Netzke.Grid.EventHandlers", {
  override: "Netzke.Grid.EventHandlers",
  netzkeHandleItemdblclick(view, record) {
    if (this.editsInline) return; // inline editing is handled elsewhere

    // MONKEY: add view in form capability
    const hasPerm = this.permissions || {};
    if (hasPerm.read !== false && !hasPerm.update) {
      this.doViewInForm(record);
    } else if (hasPerm.update !== false) {
      this.doEditInForm(record);
    }
  },

  netzkeReloadStore(opts = {}) {
    const store = this.getStore();

    // MONKEY: add beforenetzkereload and netzkerevent on store
    store.fireEvent("beforenetzkereload");
    const callback = opts.callback;
    opts.callback = function() {
      if (callback) {
        callback();
      }
      store.fireEvent("netzkereload");
    };

    // NETZKE'S HACK to work around buffered store's buggy reload()
    if (!store.lastRequestStart) {
      store.load(opts);
    } else store.reload(opts);
  }
});

Ext.define("Ext.toolbar.Paging", {
  override: "Ext.toolbar.Paging",

  handleRefresh: Ext.emptyFn,

  doRefresh() {
    const me = this,
      current = me.store.currentPage;

    // MONKEY: add netzkerefresh to ExtJS paging toolbar refresh
    // as beforechange is too generic
    me.store.fireEvent("netzkerefresh", me);

    if (me.fireEvent("beforechange", me, current) !== false) {
      me.store.loadPage(current);

      me.handleRefresh();
    }
  }
});

Ext.define("Netzke.Grid.Columns", {
  override: "Netzke.Grid.Columns",
  netzkeNormalizeAssociationRenderer(c) {
    const passedRenderer = c.renderer; // renderer we got from netzkeNormalizeRenderer
    let assocValue;
    c.scope = this;
    c.renderer = function(value, a, r, ri, ci, store, view) {
      const column = view.headerCt.items.getAt(ci);
      const editor = column.getEditor && column.getEditor();
      /* MONKEY: use findRecordByValue instead of findRecord to remedy inline editing temporarily
	     changing N/A columns to the recently changed value.
	  */
      const recordFromStore =
        editor && editor.isXType("combobox") && editor.findRecordByValue(value);
      let renderedValue;

      if (recordFromStore) {
        renderedValue = recordFromStore.get("text");
      } else if (
        (assocValue = (r.get("association_values") || {})[c.name]) !== undefined
      ) {
        renderedValue = assocValue == undefined ? c.emptyText : assocValue;
      } else {
        renderedValue = value;
      }

      return passedRenderer
        ? passedRenderer.call(this, renderedValue)
        : renderedValue;
    };
  }
});

/*

This is a modified version of the ExtJS Codemirror component from
http://www.mzsolutions.eu/Extjs-CodeMirror-component.html.  It's been
modified to remove the toolbar and also it uses delorean mode by
default.

*/

/**
 * @private
 * @class Ext.ux.layout.component.field.CodeMirror
 * @extends Ext.layout.component.field.Field
 * @author Adrian Teodorescu (ateodorescu@gmail.com)
 *
 * Layout class for {@link Ext.ux.form.field.CodeMirror} fields. Handles sizing the codemirror field.
 */
Ext.define("Ext.ux.layout.component.field.CodeMirror", {
  extend: "Ext.layout.component.Auto",
  alias: ["layout.codemirror"],

  type: "codemirror",

  beginLayout(ownerContext) {
    this.callParent(arguments);

    ownerContext.textAreaContext = ownerContext.getEl("textareaEl");
    ownerContext.editorContext = ownerContext.getEl("editorEl");
  },

  renderItems: Ext.emptyFn,

  getRenderTarget() {
    return this.owner.bodyEl;
  },

  publishInnerHeight(ownerContext, height) {
    const me = this,
      innerHeight =
        height -
        me.measureLabelErrorHeight(ownerContext) -
        ownerContext.bodyCellContext.getPaddingInfo().height;
    if (Ext.isNumber(innerHeight)) {
      ownerContext.textAreaContext.setHeight(innerHeight);
      ownerContext.editorContext.setHeight(innerHeight);
    } else {
      me.done = false;
    }
  },

  publishInnerWidth(ownerContext, width) {
    const me = this;

    if (Ext.isNumber(width)) {
      ownerContext.textAreaContext.setWidth(width);
      ownerContext.editorContext.setWidth(width);
    } else {
      me.done = false;
    }
  }
});

Ext.define("Ext.ux.form.field.CodeMirror", {
  extend: "Ext.Component",
  mixins: {
    labelable: "Ext.form.Labelable",
    field: "Ext.form.field.Field"
  },
  alias: "widget.codemirror",
  alternateClassName: "Ext.form.CodeMirror",
  requires: [
    "Ext.tip.QuickTipManager",
    "Ext.util.Format",
    "Ext.ux.layout.component.field.CodeMirror"
  ],

  childEls: ["editorEl", "textareaEl"],

  fieldSubTpl: [
    '<textarea id="{cmpId}-textareaEl" name="{name}" tabIndex="-1" class="{textareaCls}" ',
    'style="{size}" autocomplete="off"></textarea>',
    '<div id="{cmpId}-editorEl" class="{editorCls}" name="{editorName}" style="{size}"></div>',
    {
      disableFormats: true
    }
  ],

  // FIXME: the layout mechanism is currently busted
  // componentLayout: 'codemirror',

  editorWrapCls: Ext.baseCSSPrefix + "html-editor-wrap",

  maskOnDisable: true,

  afterBodyEl: "</div>",

  /*
    // map tabs to 4 spaces -- arman (doesn't work - may need new version)
    extraKeys: {
            "Tab": function() {
              editor.replaceSelection("   " , "end");
            }
    },
    */

  /**
   * @cfg {String} mode The default mode to use when the editor is initialized. When not given, this will default to the first mode that was loaded.
   * It may be a string, which either simply names the mode or is a MIME type associated with the mode. Alternatively,
   * it may be an object containing configuration options for the mode, with a name property that names the mode
   * (for example {name: "javascript", json: true}). The demo pages for each mode contain information about what
   * configuration parameters the mode supports.
   */
  mode: "text/plain",

  /**
   * @cfg {Boolean} showAutoIndent Enable auto indent button for indenting the selected range
   */
  showAutoIndent: true,

  /**
   * @cfg {Boolean} showLineNumbers Enable line numbers button in the toolbar.
   */
  showLineNumbers: true,

  /**
   * @cfg {Boolean} enableMatchBrackets Force matching-bracket-highlighting to happen
   */
  enableMatchBrackets: true,

  /**
   * @cfg {Boolean} enableElectricChars Configures whether the editor should re-indent the current line when a character is typed
   * that might change its proper indentation (only works if the mode supports indentation).
   */
  enableElectricChars: false,

  /**
   * @cfg {Boolean} enableIndentWithTabs Whether, when indenting, the first N*tabSize spaces should be replaced by N tabs.
   */
  enableIndentWithTabs: true,

  /**
   * @cfg {Boolean} enableSmartIndent Whether to use the context-sensitive indentation that the mode provides (or just indent the same as the line before).
   */
  enableSmartIndent: true,

  /**
   * @cfg {Boolean} enableLineWrapping Whether CodeMirror should scroll or wrap for long lines.
   */
  enableLineWrapping: false,

  /**
   * @cfg {Boolean} enableLineNumbers Whether to show line numbers to the left of the editor.
   */
  enableLineNumbers: true,

  /**
   * @cfg {Boolean} enableGutter Can be used to force a 'gutter' (empty space on the left of the editor) to be shown even
   * when no line numbers are active. This is useful for setting markers.
   */
  enableGutter: true,

  /**
   * @cfg {Boolean} enableFixedGutter When enabled (off by default), this will make the gutter stay visible when the
   * document is scrolled horizontally.
   */
  enableFixedGutter: false,

  /**
   * @cfg {Number} firstLineNumber At which number to start counting lines.
   */
  firstLineNumber: 1,

  /**
   * @cfg {Boolean} readOnly <tt>true</tt> to mark the field as readOnly.
   */
  readOnly: false,

  /**
   * @cfg {Number} pollInterval Indicates how quickly (miliseconds) CodeMirror should poll its input textarea for changes.
   * Most input is captured by events, but some things, like IME input on some browsers, doesn't generate events
   * that allow CodeMirror to properly detect it. Thus, it polls.
   */
  pollInterval: 100,

  /**
   * @cfg {Number} indentUnit How many spaces a block (whatever that means in the edited language) should be indented.
   */
  indentUnit: 4,

  /**
   * @cfg {Number} tabSize The width of a tab character.
   */
  tabSize: 4,

  /**
   * @cfg {String} theme The theme to style the editor with. You must make sure the CSS file defining the corresponding
   * .cm-s-[name] styles is loaded (see the theme directory in the distribution). The default is "default", for which
   * colors are included in codemirror.css. It is possible to use multiple theming classes at once—for example
   * "foo bar" will assign both the cm-s-foo and the cm-s-bar classes to the editor.
   */
  theme: "default",

  /**
   * @property {String} pathModes Path to the modes folder to dinamically load the required scripts. You could also
   * include all your required modes in a big script file and this path will be ignored.
   * Do not fill in the trailing slash.
   */
  pathModes: "mode",

  /**
   * @property {String} pathExtensions Path to the extensions folder to dinamically load the required scripts. You could also
   * include all your required extensions in a big script file and this path will be ignored.
   * Do not fill in the trailing slash.
   */
  pathExtensions: "lib/util",

  /**
   * @property {Array} extensions Define here extensions script dependencies; This is used by toolbar buttons to automatically
   * load the scripts before using an extension.
   */
  extensions: {
    format: {
      dependencies: ["formatting.js"]
    }
  },

  scriptsLoaded: [],
  lastMode: "",

  initComponent() {
    const me = this;

    me.callParent(arguments);

    me.initLabelable();
    me.initField();

    /*
        Fix resize issues as suggested by user koblass on the Extjs forums
        http://www.sencha.com/forum/showthread.php?167047-Ext.ux.form.field.CodeMirror-for-Ext-4.x&p=860535&viewfull=1#post860535
        */
    me.on(
      "resize",
      function() {
        if (me.editor) {
          me.editor.refresh();
        }
      },
      me
    );
  },

  getMaskTarget() {
    return this.bodyEl;
  },

  /**
   * @private override
   */
  getSubTplData() {
    const cssPrefix = Ext.baseCSSPrefix;
    return {
      $comp: this,
      cmpId: this.id,
      id: this.getInputId(),
      toolbarWrapCls: cssPrefix + "html-editor-tb",
      textareaCls: cssPrefix + "hidden",
      editorCls: cssPrefix + "codemirror",
      editorName: Ext.id(),
      //size            : 'height:100px;width:100%'
      // PennyMac: setting height to 100%.
      size: "height:100%;width:100%"
    };
  },

  getSubTplMarkup() {
    return this.getTpl("fieldSubTpl").apply(this.getSubTplData());
  },

  /**
   * @private override
   */
  onRender() {
    const me = this;

    me.callParent(arguments);
    me.editorEl = me.getEl("editorEl");
    me.bodyEl = me.getEl("bodyEl");

    me.disableItems(true);
    me.initEditor();

    me.rendered = true;
  },

  initRenderData() {
    this.beforeSubTpl = '<div class="' + this.editorWrapCls + '">';
    return Ext.applyIf(this.callParent(), this.getLabelableRenderData());
  },

  /**
   * @private override
   */
  initEditor() {
    const me = this;
    let mode = me.mode;

    // if no mode is loaded we could get an error like "Object #<Object> has no method 'startState'"
    // search mime to find script dependencies
    const item = me.getMime(me.mode);
    if (item) {
      mode = me.getMimeMode(me.mode);
      if (!mode) {
        mode = "text/x-delorean";
      }
    }

    me.editor = CodeMirror(me.editorEl, {
      matchBrackets: me.enableMatchBrackets,
      electricChars: me.enableElectricChars,
      autoClearEmptyLines: true,
      value: me.rawValue || "",
      indentUnit: me.indentUnit,
      smartIndent: me.enableSmartIndent,
      indentWithTabs: me.indentWithTabs,
      pollInterval: me.pollInterval,
      lineNumbers: me.enableLineNumbers,
      lineWrapping: me.enableLineWrapping,
      firstLineNumber: me.firstLineNumber,
      tabSize: me.tabSize,
      gutter: me.enableGutter,
      fixedGutter: me.enableFixedGutter,
      theme: me.theme,
      mode,
      onChange() {
        me.checkChange();
        //me.fireEvent('change', me, tc.from, tc.to, tc.text, tc.next || null);
      },
      onCursorActivity() {
        me.fireEvent("cursoractivity", me);
      },
      onGutterClick(editor, line, event) {
        me.fireEvent("gutterclick", me, line, event);
      },
      onFocus() {
        me.fireEvent("activate", me);
      },
      onBlur() {
        me.fireEvent("deactivate", me);
      },
      onScroll() {
        me.fireEvent("scroll", me);
      },
      onHighlightComplete() {
        me.fireEvent("highlightcomplete", me);
      },
      onUpdate() {
        me.fireEvent("update", me);
      },
      onKeyEvent(editor, event) {
        event.cancelBubble = true; // fix suggested by koblass user on Sencha forums (http://www.sencha.com/forum/showthread.php?167047-Ext.ux.form.field.CodeMirror-for-Ext-4.x&p=862029&viewfull=1#post862029)
        me.fireEvent("keyevent", me, event);
      }
    });
    //me.editor.setValue(me.rawValue);
    me.setMode(me.mode);
    me.setReadOnly(me.readOnly);
    me.fireEvent("initialize", me);

    // change the codemirror css
    const css1 = Ext.util.CSS.getRule(".CodeMirror");
    if (css1) {
      css1.style.height = "100%";
      css1.style.position = "relative";
      css1.style.overflow = "hidden";
    }

    const css2 = Ext.util.CSS.getRule(".CodeMirror-Scroll");
    if (css2) {
      css2.style.height = "100%";
    }

    // PennyMac: align the body to the top. Otherwise it ends up
    // in the center of the enclosing table.
    const el = document.getElementById(me.bodyEl.id);
    el.setAttribute("valign", "top");
  },

  /**
   * @private
   */
  relayBtnCmd(btn) {
    this.relayCmd(btn.getItemId());
  },

  /**
   * @private
   */
  relayCmd(cmd) {
    Ext.defer(
      function() {
        const me = this;
        me.editor.focus();
        switch (cmd) {
          // auto formatting
          case "justifycenter":
            if (!CodeMirror.extensions.autoIndentRange) {
              me.loadDependencies(
                me.extensions.format,
                me.pathExtensions,
                me.doIndentSelection,
                me
              );
            } else {
              me.doIndentSelection();
            }
            break;

          // line numbers
          case "insertorderedlist":
            me.doChangeLineNumbers();
            break;
        }
      },
      10,
      this
    );
  },

  /**
   * @private
   * Reload all CodeMirror extensions for the current instance;
   *
   */
  reloadExtentions() {
    const me = this;

    for (const ext in CodeMirror.extensions)
      if (
        Object.prototype.propertyIsEnumerable.call(
          CodeMirror.extensions,
          ext
        ) &&
        !Object.prototype.propertyIsEnumerable.call(me.editor, ext)
      )
        me.editor[ext] = CodeMirror.extensions[ext];
  },

  doChangeLineNumbers() {
    const me = this;

    me.enableLineNumbers = !me.enableLineNumbers;
    me.editor.setOption("lineNumbers", me.enableLineNumbers);
  },

  /**
   * @private
   */
  doIndentSelection() {
    const me = this;

    me.reloadExtentions();

    try {
      const range = {
        from: me.editor.getCursor(true),
        to: me.editor.getCursor(false)
      };
      me.editor.autoIndentRange(range.from, range.to);
    } catch (err) {
      // do nothing
    }
  },

  modes: [
    {
      mime: CodeMirror.mimeModes,
      dependencies: []
    }
  ],

  /**
   * @private
   */
  getMime(mime) {
    const me = this;
    let item,
      found = false;

    for (let i = 0; i < me.modes.length; i++) {
      item = me.modes[i];
      if (Ext.isArray(item.mime)) {
        if (Ext.Array.contains(item.mime, mime)) {
          found = true;
          break;
        }
      } else {
        if (item == mime) {
          found = true;
          break;
        }
      }
    }
    if (found) return item;
    else return null;
  },

  /**
   * @private
   */
  loadDependencies(item, path, handler, scope) {
    const me = this;

    me.scripts = [];
    me.scriptIndex = -1;

    // load the dependencies
    for (let i = 0; i < item.dependencies.length; i++) {
      if (
        !Ext.Array.contains(me.scriptsLoaded, path + "/" + item.dependencies[i])
      ) {
        me.scriptIndex += 1;

        const options = {
          url: path + "/" + item.dependencies[i],
          index: me.scriptIndex,
          onLoad() {
            let ok = true;
            for (let j = 0; j < me.scripts.length; j++) {
              if (me.scripts[j].called) {
                // this event could be raised before one script if fetched
                ok = ok && me.scripts[j].success;
                if (
                  me.scripts[j].success &&
                  !Ext.Array.contains(me.scriptsLoaded, me.scripts[j].url)
                ) {
                  me.scriptsLoaded.push(me.scripts[j].url);
                }
              } else {
                ok = false;
              }
            }
            if (ok) {
              handler.call(scope || me.editor);
            }
          }
        };

        me.scripts[me.scriptIndex] = {
          url: options.url,
          success: true,
          called: false,
          options,
          onLoad: options.onLoad || Ext.emptyFn,
          onError: options.onError || Ext.emptyFn
        };
      }
    }

    for (let k = 0; k < me.scripts.length; k++) {
      me.loadScript(me.scripts[k].options);
    }
  },

  /**
   * @private
   */
  loadScript(options) {
    const me = this;
    Ext.Ajax.request({
      url: options.url,
      scriptIndex: options.index,
      success(response, options) {
        const script =
          'Ext.getCmp("' + this.id + '").scripts[' + options.scriptIndex + "]";
        window.setTimeout(
          "try { " +
            response.responseText +
            " } catch(e) { " +
            script +
            ".success = false; " +
            script +
            ".onError(" +
            script +
            ".options, e); };  " +
            script +
            ".called = true; if (" +
            script +
            ".success) " +
            script +
            ".onLoad(" +
            script +
            ".options);",
          0
        );
      },
      failure(response, options) {
        const script = this.scripts[options.scriptIndex];
        script.success = false;
        script.called = true;
        script.onError(script.options, response.status);
      },
      scope: me
    });
  },

  /**
   * @private
   * Return mode depending on the mime; If the mime is not loaded then return null
   *
   * @param mime
   */
  getMimeMode(mime) {
    let mode = null;
    const mimes = CodeMirror.mimeModes;
    for (let i = 0; i < mimes.length; i++) {
      if (mimes[i].mime == mime) {
        mode = mimes[i].mode;
        if (typeof mode == "object") mode = mode.name;
        break;
      }
    }
    return mode;
  },

  /**
   * Change the CodeMirror mode to the specified mime.
   *
   * @param {String} mime The MIME value according to the CodeMirror documentation
   */
  setMode(mime) {
    const me = this;
    // found = false;
    // search mime to find script dependencies
    const item = me.getMime(mime);

    if (!item) {
      // mime not found
      return;
    }

    const mode = me.getMimeMode(mime);

    if (!mode) {
      me.loadDependencies(item, me.pathModes, function() {
        const mode = me.getMimeMode(mime);
        if (typeof mode == "string") me.editor.setOption("mode", mime);
        else me.editor.setOption("mode", mode);
      });
    } else {
      if (typeof mode == "string") me.editor.setOption("mode", mime);
      else me.editor.setOption("mode", mode);
    }

    if (me.modesSelect) {
      me.modesSelect.dom.value = mime;
    }
    try {
      me.fireEvent("modechanged", me, mime, me.lastMode);
      me.lastMode = mime;
    } catch (err) {
      // do nothing
    }
  },

  /**
   * Set the editor as read only
   *
   * @param {Boolean} readOnly
   */
  setReadOnly(readOnly) {
    const me = this;

    if (me.editor) {
      me.editor.setOption("readOnly", readOnly);
      me.disableItems(readOnly);
    }
  },

  onDisable() {
    this.bodyEl.mask();
    this.callParent(arguments);
  },

  onEnable() {
    this.bodyEl.unmask();
    this.callParent(arguments);
  },

  disableItems() {},

  /**
   * Sets a data value into the field and runs the change detection.
   * @param {Mixed} value The value to set
   * @return {Ext.ux.form.field.CodeMirror} this
   */
  setValue(value) {
    const me = this;

    me.mixins.field.setValue.call(me, value);
    me.rawValue = value;
    if (me.editor) me.editor.setValue(value);
    return me;
  },

  /**
   * Return submit value to the owner form.
   * @return {Mixed} The field value
   */
  getSubmitValue() {
    const me = this;
    return me.getValue();
  },

  /**
   * Return the value of the CodeMirror editor
   * @return {Mixed} The field value
   */
  getValue() {
    const me = this;

    if (me.editor) return me.editor.getValue();
    else return null;
  },

  /**
   * @private
   */
  onDestroy() {
    const me = this;
    if (me.rendered) {
      try {
        Ext.EventManager.removeAll(me.editor);
        for (const prop in me.editor) {
          if (Object.prototype.hasOwnProperty.call(me.editor, prop)) {
            delete me.editor[prop];
          }
        }
      } catch (e) {
        // do nothing
      }
    }
    me.callParent();
  }
});

// There is an error with code tester. Sometimes the Ext app craches when you click test again after some time passed
// The bug is present in Ext 6.5.3.57
// HACK FIX. This error happens when OuterCt/InnerCt dom was removed, but components thinks that it's still there
// Uncaught TypeError: Cannot read property 'style' of null
//    at constructor.setStyle (ext-all-debug.js:42950)
//    at constructor.beginLayoutCycle (ext-all-debug.js:150619)
//
//    check for outerCt.destroyed value. If it's destroyed then it's dom is gone and
//    and it's style and dimentions are not available
//    If it's not destroyed go with regular way
Ext.define("Marty.layout.container.Auto", {
  override: "Ext.layout.container.Auto",

  // Sometimes outerCt is already destroyed. in that case it's DOM is null and all methods
  // that call DOM should not be called
  beginLayoutCycle(ownerContext) {
    const me = this;
    const outerCt = me.outerCt;
    const lastOuterCtWidth = me.lastOuterCtWidth || "";
    const lastOuterCtHeight = me.lastOuterCtHeight || "";
    const lastOuterCtTableLayout = me.lastOuterCtTableLayout || "";
    const state = ownerContext.state;
    let overflowXStyle;
    let outerCtWidth;
    let outerCtHeight;
    let outerCtTableLayout;
    let inheritedStateInner;

    // FIX
    //- me.callParent(arguments);
    // If callParent would call overriden method, which leads to and exception
    // when outerCt is destroyed. In that case we use callSuper, which ignores overriden method.
    // If outerCt is not destroyed, then we call overriden method and exit the function. Fixes bellow are not needed
    if (outerCt.destroyed) {
      me.callSuper(arguments);
    } else {
      return me.callParent(arguments);
    }

    // Default to "shrink wrap styles".
    outerCtWidth = outerCtHeight = outerCtTableLayout = "";
    if (!ownerContext.widthModel.shrinkWrap) {
      // if we're not shrink wrapping width, we need to get the innerCt out of the
      // way to avoid any shrink wrapping effect on child items
      // fill the available width within the container
      outerCtWidth = "100%";
      inheritedStateInner = me.owner.inheritedStateInner;
      // expand no further than the available width, even if contents are wider
      // unless there is a potential for horizontal overflow, then allow
      // the outerCt to expand to the width of the contents
      overflowXStyle = me.getOverflowXStyle(ownerContext);
      outerCtTableLayout =
        inheritedStateInner.inShrinkWrapTable ||
        overflowXStyle === "auto" ||
        overflowXStyle === "scroll"
          ? ""
          : "fixed";
    }
    if (
      !ownerContext.heightModel.shrinkWrap &&
      !Ext.supports.PercentageHeightOverflowBug
    ) {
      // if we're not shrink wrapping height, we need to get the outerCt out of the
      // way so that percentage height children will be sized correctly.  We do this
      // by giving the outerCt a height of '100%' unless the browser is affected by
      // the "percentage height overflow bug", in which case the outerCt will get a
      // pixel height set during the calculate phase after we know the targetEl size.
      outerCtHeight = "100%";
    }
    // if the outerCt width changed since last time (becuase of a widthModel change)
    // or if we set a pixel width on the outerCt last time to work around a browser-
    // specific bug, we need to set the width of the outerCt
    if (outerCtWidth !== lastOuterCtWidth || me.hasOuterCtPxWidth) {
      // FIX: Added check for !outerCt.destroyed
      if (!outerCt.destroyed) {
        outerCt.setStyle("width", outerCtWidth);
      }
      me.lastOuterCtWidth = outerCtWidth;
      me.hasOuterCtPxWidth = false;
    }
    // Set the outerCt table-layout property if different from last time.
    if (outerCtTableLayout !== lastOuterCtTableLayout) {
      outerCt.setStyle("table-layout", outerCtTableLayout);
      me.lastOuterCtTableLayout = outerCtTableLayout;
    }
    // if the outerCt height changed since last time (becuase of a heightModel change)
    // or if we set a pixel height on the outerCt last time to work around a browser-
    // specific bug, we need to set the height of the outerCt
    if (outerCtHeight !== lastOuterCtHeight || me.hasOuterCtPxHeight) {
      // FIX: Added check for !outerCt.destroyed
      if (!outerCt.destroyed) {
        outerCt.setStyle("height", outerCtHeight);
      }
      me.lastOuterCtHeight = outerCtHeight;
      me.hasOuterCtPxHeight = false;
    }
    if (me.hasInnerCtPxHeight) {
      // FIX: Added check for !innerCt.destroyed
      if (!me.innerCt.destroyed) {
        me.innerCt.setStyle("height", "");
      }
      me.hasInnerCtPxHeight = false;
    }
    // Begin with the scrollbar adjustment that we used last time - this is more likely
    // to be correct than beginning with no adjustment at all, but only if it is not
    // already defined - it may have already been set by invalidate()
    state.overflowAdjust = state.overflowAdjust || me.lastOverflowAdjust;
  },

  // The fix checks whether outerCt is destroyed or not
  // If it's destroyed, then the dom is gone and calling getHeight() would lead to exception
  // set contentHeight to 0 if outerCt is destroyed
  measureContentHeight(ownerContext) {
    // contentHeight includes padding, but not border, framing or margins
    // FIX
    // var contentHeight = this.outerCt.getHeight();
    let contentHeight = this.outerCt.destroyed ? 0 : this.outerCt.getHeight();
    // END FIX
    const target = ownerContext.target;

    if (
      this.managePadding &&
      target[target.contentPaddingProperty] === undefined
    ) {
      // if padding was not configured using the appropriate contentPaddingProperty
      // then the padding will not be on the paddingContext, and therfore not included
      // in the outerCt measurement, so we need to read the padding from the
      // targetContext
      contentHeight += ownerContext.targetContext.getPaddingInfo().height;
    }
    return contentHeight;
  }
});

Ext.define("overrides.grid.column.Column", {
  override: "Ext.grid.column.Column",

  initConfig(config) {
    if (!config.renderer && !this.updater) {
      config.formatter = "htmlEncode";
    }
    return this.callParent(arguments);
  }
});

Ext.define("Ext.netzke.marty.MultiSelectCombo", {
  extend: "Ext.form.ComboBox",
  alias: "widget.multiselectcombo",
  separator: ",",
  multiSelect: true,

  setValue(v) {
    if (Ext.isString(v)) {
      const vArray = v.split(this.separator);
      this.callParent([vArray]);
    } else {
      this.callParent(arguments);
    }
  }
});

// Fix component fetching in ExtJS 7
// This flag was false by default in ExtJS 6
Ext.USE_NATIVE_JSON = false;
