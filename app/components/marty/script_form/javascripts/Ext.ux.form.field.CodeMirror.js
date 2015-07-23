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
Ext.define('Ext.ux.layout.component.field.CodeMirror', {
    extend: 'Ext.layout.component.Auto',
    alias: ['layout.codemirror'],

    type: 'codemirror',

    beginLayout: function(ownerContext) {
        this.callParent(arguments);

        ownerContext.textAreaContext = ownerContext.getEl('textareaEl');
        ownerContext.editorContext   = ownerContext.getEl('editorEl');
    },

    renderItems: Ext.emptyFn,

    getRenderTarget: function() {
        return this.owner.bodyEl;
    },

    publishInnerHeight: function (ownerContext, height) {
        var me = this,
            innerHeight = height - me.measureLabelErrorHeight(ownerContext) -
                          ownerContext.bodyCellContext.getPaddingInfo().height;
        if (Ext.isNumber(innerHeight)) {
            ownerContext.textAreaContext.setHeight(innerHeight);
            ownerContext.editorContext.setHeight(innerHeight);
        } else {
            me.done = false;
        }
    },

    publishInnerWidth: function (ownerContext, width) {
        var me = this;

        if (Ext.isNumber(width)) {
            ownerContext.textAreaContext.setWidth(width);
            ownerContext.editorContext.setWidth(width);
        } else {
            me.done = false;
        }
    }
});

Ext.define('Ext.ux.form.field.CodeMirror', {
    extend: 'Ext.Component',
    mixins: {
        labelable: 'Ext.form.Labelable',
        field: 'Ext.form.field.Field'
    },
    alias: 'widget.codemirror',
    alternateClassName: 'Ext.form.CodeMirror',
    requires: [
        'Ext.tip.QuickTipManager',
        'Ext.util.Format',
        'Ext.ux.layout.component.field.CodeMirror'
    ],

    childEls: [
        'editorEl', 'textareaEl'
    ],

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

    editorWrapCls: Ext.baseCSSPrefix + 'html-editor-wrap',

    maskOnDisable: true,

    afterBodyEl: '</div>',

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
    mode:               'text/plain',

    /**
    * @cfg {Boolean} showAutoIndent Enable auto indent button for indenting the selected range
    */
    showAutoIndent:     true,

    /**
    * @cfg {Boolean} showLineNumbers Enable line numbers button in the toolbar.
    */
    showLineNumbers:    true,

    /**
    * @cfg {Boolean} enableMatchBrackets Force matching-bracket-highlighting to happen
    */
    enableMatchBrackets:    true,

    /**
    * @cfg {Boolean} enableElectricChars Configures whether the editor should re-indent the current line when a character is typed
    * that might change its proper indentation (only works if the mode supports indentation).
    */
    enableElectricChars:    false,

    /**
    * @cfg {Boolean} enableIndentWithTabs Whether, when indenting, the first N*tabSize spaces should be replaced by N tabs.
    */
    enableIndentWithTabs:   true,

    /**
    * @cfg {Boolean} enableSmartIndent Whether to use the context-sensitive indentation that the mode provides (or just indent the same as the line before).
    */
    enableSmartIndent:      true,

    /**
    * @cfg {Boolean} enableLineWrapping Whether CodeMirror should scroll or wrap for long lines.
    */
    enableLineWrapping:     false,

    /**
    * @cfg {Boolean} enableLineNumbers Whether to show line numbers to the left of the editor.
    */
    enableLineNumbers:      true,

    /**
    * @cfg {Boolean} enableGutter Can be used to force a 'gutter' (empty space on the left of the editor) to be shown even
    * when no line numbers are active. This is useful for setting markers.
    */
    enableGutter:           true,

    /**
    * @cfg {Boolean} enableFixedGutter When enabled (off by default), this will make the gutter stay visible when the
    * document is scrolled horizontally.
    */
    enableFixedGutter:      false,

    /**
    * @cfg {Number} firstLineNumber At which number to start counting lines.
    */
    firstLineNumber:         1,

    /**
     * @cfg {Boolean} readOnly <tt>true</tt> to mark the field as readOnly.
     */
    readOnly : false,

    /**
    * @cfg {Number} pollInterval Indicates how quickly (miliseconds) CodeMirror should poll its input textarea for changes.
    * Most input is captured by events, but some things, like IME input on some browsers, doesn't generate events
    * that allow CodeMirror to properly detect it. Thus, it polls.
    */
    pollInterval:         100,

    /**
    * @cfg {Number} indentUnit How many spaces a block (whatever that means in the edited language) should be indented.
    */
    indentUnit:         4,

    /**
    * @cfg {Number} tabSize The width of a tab character.
    */
    tabSize:            4,

    /**
    * @cfg {String} theme The theme to style the editor with. You must make sure the CSS file defining the corresponding
    * .cm-s-[name] styles is loaded (see the theme directory in the distribution). The default is "default", for which
    * colors are included in codemirror.css. It is possible to use multiple theming classes at once—for example
    * "foo bar" will assign both the cm-s-foo and the cm-s-bar classes to the editor.
    */
    theme:              'default',

    /**
    * @property {String} pathModes Path to the modes folder to dinamically load the required scripts. You could also
    * include all your required modes in a big script file and this path will be ignored.
    * Do not fill in the trailing slash.
    */
    pathModes:          'mode',

    /**
    * @property {String} pathExtensions Path to the extensions folder to dinamically load the required scripts. You could also
    * include all your required extensions in a big script file and this path will be ignored.
    * Do not fill in the trailing slash.
    */
    pathExtensions:     'lib/util',

    /**
    * @property {Array} extensions Define here extensions script dependencies; This is used by toolbar buttons to automatically
    * load the scripts before using an extension.
    */
    extensions:{
        format: {
            dependencies: ['formatting.js']
        }
    },

    scriptsLoaded: [],
    lastMode: '',

    initComponent : function(){
        var me = this;

        me.callParent(arguments);

        me.initLabelable();
        me.initField();

        /*
        Fix resize issues as suggested by user koblass on the Extjs forums
        http://www.sencha.com/forum/showthread.php?167047-Ext.ux.form.field.CodeMirror-for-Ext-4.x&p=860535&viewfull=1#post860535
        */
        me.on('resize', function() {
            if (me.editor) {
                me.editor.refresh();
            }
        }, me);
    },

    getMaskTarget: function(){
        return this.bodyEl;
    },

    /**
    * @private override
    */
    getSubTplData: function() {
        var cssPrefix = Ext.baseCSSPrefix;
        return {
            $comp           : this,
            cmpId           : this.id,
            id              : this.getInputId(),
            toolbarWrapCls  : cssPrefix + 'html-editor-tb',
            textareaCls     : cssPrefix + 'hidden',
            editorCls       : cssPrefix + 'codemirror',
            editorName      : Ext.id(),
            //size            : 'height:100px;width:100%'
            // PennyMac: setting height to 100%.
            size            : 'height:100%;width:100%',
        };
    },

    getSubTplMarkup: function() {
        return this.getTpl('fieldSubTpl').apply(this.getSubTplData());
    },

    /**
    * @private override
    */
    onRender: function() {
        var me = this;

        me.callParent(arguments);
        me.editorEl = me.getEl('editorEl');
        me.bodyEl = me.getEl('bodyEl');

        me.disableItems(true);
        me.initEditor();

        me.rendered = true;
    },

    initRenderData: function() {
        this.beforeSubTpl = '<div class="' + this.editorWrapCls + '">';
        return Ext.applyIf(this.callParent(), this.getLabelableRenderData());
    },

    /**
    * @private override
    */
    initEditor : function(){
        var me = this,
        mode = "text/x-delorean";

        // if no mode is loaded we could get an error like "Object #<Object> has no method 'startState'"
        // search mime to find script dependencies
        var item = me.getMime(me.mode);
        if(item) {
            mode = me.getMimeMode(me.mode);
            if(!mode){
                mode = "text/x-delorean";
            }
        }

        me.editor = CodeMirror(me.editorEl, {
            matchBrackets:      me.enableMatchBrackets,
            electricChars:      me.enableElectricChars,
            autoClearEmptyLines:true,
            value:              me.rawValue,
            indentUnit:         me.indentUnit,
            smartIndent:        me.enableSmartIndent,
            indentWithTabs:     me.indentWithTabs,
            pollInterval:       me.pollInterval,
            lineNumbers:        me.enableLineNumbers,
            lineWrapping:       me.enableLineWrapping,
            firstLineNumber:    me.firstLineNumber,
            tabSize:            me.tabSize,
            gutter:             me.enableGutter,
            fixedGutter:        me.enableFixedGutter,
            theme:              me.theme,
            mode:               mode,
            onChange:           function(editor, tc){
                me.checkChange();
                //me.fireEvent('change', me, tc.from, tc.to, tc.text, tc.next || null);
            },
            onCursorActivity:   function(editor){
                me.fireEvent('cursoractivity', me);
            },
            onGutterClick:      function(editor, line, event){
                me.fireEvent('gutterclick', me, line, event);
            },
            onFocus:            function(editor){
                me.fireEvent('activate', me);
            },
            onBlur:             function(editor){
                me.fireEvent('deactivate', me);
            },
            onScroll:           function(editor){
                me.fireEvent('scroll', me);
            },
            onHighlightComplete: function(editor){
                me.fireEvent('highlightcomplete', me);
            },
            onUpdate:           function(editor){
                me.fireEvent('update', me);
            },
            onKeyEvent:         function(editor, event){
                event.cancelBubble = true; // fix suggested by koblass user on Sencha forums (http://www.sencha.com/forum/showthread.php?167047-Ext.ux.form.field.CodeMirror-for-Ext-4.x&p=862029&viewfull=1#post862029)
                me.fireEvent('keyevent', me, event);
            }
        });
        //me.editor.setValue(me.rawValue);
        me.setMode(me.mode);
        me.setReadOnly(me.readOnly);
        me.fireEvent('initialize', me);

        // change the codemirror css
        var css = Ext.util.CSS.getRule('.CodeMirror');
        if(css){
            css.style.height = '100%';
            css.style.position = 'relative';
            css.style.overflow = 'hidden';
        }
        var css = Ext.util.CSS.getRule('.CodeMirror-Scroll');
        if(css){
            css.style.height = '100%';
        }

        // PennyMac: align the body to the top. Otherwise it ends up
        // in the center of the enclosing table.
        var el = document.getElementById(me.bodyEl.id);
        el.setAttribute("valign", "top");
    },

    /**
    * @private
    */
    relayBtnCmd: function(btn){
        this.relayCmd(btn.getItemId());
    },

    /**
    * @private
    */
    relayCmd: function(cmd){
        Ext.defer(function() {
            var me = this;
            me.editor.focus();
            switch(cmd){
                // auto formatting
                case 'justifycenter':
                    if(!CodeMirror.extensions.autoIndentRange){
                        me.loadDependencies(me.extensions.format, me.pathExtensions, me.doIndentSelection, me);
                    }else{
                        me.doIndentSelection();
                    }
                break;

                // line numbers
                case 'insertorderedlist':
                    me.doChangeLineNumbers();
                break;
            }
        }, 10, this);
    },

    /**
    * @private
    * Reload all CodeMirror extensions for the current instance;
    *
    */
    reloadExtentions: function(){
        var me = this;

        for (var ext in CodeMirror.extensions)
          if (CodeMirror.extensions.propertyIsEnumerable(ext) &&
              !me.editor.propertyIsEnumerable(ext))
            me.editor[ext] = CodeMirror.extensions[ext];
    },

    doChangeLineNumbers: function(){
        var me = this;

        me.enableLineNumbers = !me.enableLineNumbers;
        me.editor.setOption('lineNumbers', me.enableLineNumbers);
    },

    /**
    * @private
    */
    doIndentSelection: function(){
        var me = this;

        me.reloadExtentions();

        try{
            var range = { from: me.editor.getCursor(true), to: me.editor.getCursor(false) };
            me.editor.autoIndentRange(range.from, range.to);
        }catch(err){}
    },

    modes: [
        {
            mime:           ["text/x-delorean"],
            dependencies:   []
        },
    ],

    /**
    * @private
    */
    getMime: function(mime){
        var me = this, item, found = false;

        for(var i=0;i<me.modes.length;i++){
            item = me.modes[i];
            if(Ext.isArray(item.mime)){
                if(Ext.Array.contains(item.mime, mime)){
                    found = true;
                    break;
                }
            }else{
                if(item == mime){
                    found = true;
                    break;
                }
            }
        }
        if(found)
            return item;
        else
            return null;
    },

    /**
    * @private
    */
    loadDependencies: function(item, path, handler, scope){
        var me = this;

        me.scripts = [];
        me.scriptIndex = -1;

        // load the dependencies
        for(var i=0; i < item.dependencies.length; i++){
            if(!Ext.Array.contains(me.scriptsLoaded, path + '/' + item.dependencies[i])){
                var options = {
                    url: path + '/' + item.dependencies[i],
                    index: ++me.scriptIndex,
                    onLoad: function(options){
                        var ok = true;
                        for(j=0; j < me.scripts.length; j++){
                            if(me.scripts[j].called) {// this event could be raised before one script if fetched
                                ok = ok && me.scripts[j].success;
                                if(me.scripts[j].success && !Ext.Array.contains(me.scriptsLoaded, me.scripts[j].url)){
                                    me.scriptsLoaded.push(me.scripts[j].url);
                                }
                            }else{
                                ok = false;
                            }
                        }
                        if(ok){
                            handler.call(scope || me.editor);
                        }
                    }
                };

                me.scripts[me.scriptIndex] = {
                    url: options.url,
                    success: true,
                    called: false,
                    options: options,
                    onLoad: options.onLoad || Ext.emptyFn,
                    onError: options.onError || Ext.emptyFn
                };
            }
        }
        for(var i=0; i < me.scripts.length; i++){
            me.loadScript(me.scripts[i].options);
        }
    },

    /**
    * @private
    */
    loadScript: function(options){
        var me = this;
        Ext.Ajax.request({
            url: options.url,
            scriptIndex: options.index,
            success: function(response, options) {
                var script = 'Ext.getCmp("' + this.id + '").scripts[' + options.scriptIndex + ']';
                window.setTimeout('try { ' + response.responseText + ' } catch(e) { '+script+'.success = false; '+script+'.onError('+script+'.options, e); };  ' + script + '.called = true; if ('+script+'.success) '+script+'.onLoad('+script+'.options);', 0);
            },
            failure: function(response, options) {
                var script = this.scripts[options.scriptIndex];
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
    getMimeMode: function(mime){
        var mode = null;
        var mimes = CodeMirror.listMIMEs();
        for(var i=0; i<mimes.length; i++){
            if(mimes[i].mime == mime){
                mode = mimes[i].mode;
                if(typeof mode == "object")
                    mode = mode.name;
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
    setMode: function(mime){
        var me = this,
            found = false;
        // search mime to find script dependencies
        var item = me.getMime(mime);

        if(!item) {
            // mime not found
            return;
        }

        var mode = me.getMimeMode(mime);

        if(!mode){
            me.loadDependencies(item, me.pathModes, function(){
                var mode = me.getMimeMode(mime);
                if(typeof mode == "string")
                    me.editor.setOption('mode', mime);
                else
                    me.editor.setOption('mode', mode);
            });
        }else{
            if(typeof mode == "string")
                me.editor.setOption('mode', mime);
            else
                me.editor.setOption('mode', mode);
        }

        if(me.modesSelect){
            me.modesSelect.dom.value = mime;
        }
        try{
            me.fireEvent('modechanged', me, mime, me.lastMode);
            me.lastMode = mime;
        }catch(err){}
    },

    /**
    * Set the editor as read only
    *
    * @param {Boolean} readOnly
    */
    setReadOnly: function(readOnly) {
        var me = this;

        if(me.editor){
            me.editor.setOption('readOnly', readOnly);
            me.disableItems(readOnly);
        }
    },

    onDisable: function() {
        this.bodyEl.mask();
        this.callParent(arguments);
    },

    onEnable: function() {
        this.bodyEl.unmask();
        this.callParent(arguments);
    },

    disableItems: function(disabled) {
    },

    /**
    * Sets a data value into the field and runs the change detection.
    * @param {Mixed} value The value to set
    * @return {Ext.ux.form.field.CodeMirror} this
    */
    setValue: function(value){
        var me = this;

        me.mixins.field.setValue.call(me, value);
        me.rawValue = value;
        if(me.editor)
            me.editor.setValue(value);
        return me;
    },

    /**
    * Return submit value to the owner form.
    * @return {Mixed} The field value
    */
    getSubmitValue: function(){
        var me = this;
        return me.getValue();
    },

    /**
    * Return the value of the CodeMirror editor
    * @return {Mixed} The field value
    */
    getValue: function(){
        var me = this;

        if(me.editor)
            return me.editor.getValue();
        else
            return null;
    },

    /**
    * @private
    */
    onDestroy: function(){
        var me = this;
        if(me.rendered){
            try {
                Ext.EventManager.removeAll(me.editor);
                for (prop in me.editor) {
                    if (me.editor.hasOwnProperty(prop)) {
                        delete me.editor[prop];
                    }
                }
            }catch(e){}
        }
        me.callParent();
    },

});
