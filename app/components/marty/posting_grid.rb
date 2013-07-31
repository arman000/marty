class Marty::PostingGrid < Marty::CmGridPanel
  def configure(c)
    super

    c.header 	= false
    c.model 	= "Marty::Posting"
    c.columns 	= [:name, :created_dt, :user__name, :comment]
    c.data_store.sorters = {property: :created_dt, direction: 'DESC'}
  end

  # hijacking delete button
  action :del do |a|
    a.text 	= "Select"
    a.tooltip  	= "Select"
    a.icon 	= :time_go
    a.disabled 	= true
  end

  js_configure do |c|
    c.init_component = <<-JS
      function() {
        this.callParent();
	// Set single selection mode. FIXME: can this be done on config?
	this.getSelectionModel().setSelectionMode('SINGLE');
      }
      JS

    c.on_del = <<-JS
      function() {
        var records = [];
	var me = this;
        me.getSelectionModel().selected.each(function(r) {
           records.push(r.getId());
        }, me);

	// find the root component (main application)
	var main_app = me;
	while (1) {
	  var p = main_app.netzkeGetParentComponent();
	  if (!p) { break; }
	  main_app = p;
	}

	// assumes main_app has serverSelectPosting method
        main_app.serverSelectPosting(records);
      }
      JS
  end

  def default_bbar
    [:del]
  end

  column :name do |c|
    c.flex 	= 1
  end

  column :created_dt do |c|
    c.text 	= "Date/Time"
    c.format 	= "Y-m-d H:i"
    c.hidden 	= true
  end

  column :user__name do |c|
    c.width 	= 100
  end

  column :comment do |c|
    c.width 	= 100
  end

end

PostingGrid = Marty::PostingGrid
