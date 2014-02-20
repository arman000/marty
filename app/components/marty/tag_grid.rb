class Marty::TagGrid < Marty::CmGridPanel
  has_marty_permissions read: :any

  def configure(c)
    super

    c.header	= false
    c.model	= "Marty::Tag"
    c.columns	||= [:name, :created_dt, :user__name, :comment]
    c.data_store.sorters = {property: :created_dt, direction: 'DESC'}
  end

  js_configure do |c|
    c.init_component = <<-JS
    function() {
       this.callParent();
       // Set single selection mode. FIXME: can this be done on config?
       this.getSelectionModel().setSelectionMode('SINGLE');
       this.getSelectionModel().on('selectionchange', function(selModel) {
          this.actions.detail &&
          this.actions.detail.setDisabled(!selModel.hasSelection());
       }, this);
    }
    JS

    c.detail = <<-JS
    function() {
       record_id = this.getSelectionModel().selected.first().getId();
       this.serverDetail({record_id: record_id});
    }
    JS

    c.show_detail = <<-JS
    function(details) {
      Ext.create('Ext.Window', {
        height:		150,
        minWidth:	250,
        autoWidth:	true,
        modal:		true,
        autoScroll:	true,
        html:		details,
        title:		"Tag Details"
     }).show();
    }
    JS

  end

  def default_bbar
    [:detail]
  end

  action :detail do |a|
    a.text	= "Detail"
    a.icon	= :application_view_detail
    a.handler	= :detail
    a.disabled	= true
  end

  endpoint :server_detail do |params, this|
    record_id = params[:record_id]
    pt = Marty::Tag.find_by_id(record_id)

    dt = Mcfly::Model::INFINITIES.member?(pt.created_dt) ? '---' :
      pt.created_dt.strftime('%Y-%m-%d %I:%M %p')

    html =
      "<b>Name:</b>\t#{pt.name}<br/>" +
      "<b>Date/Time:</b>\t#{dt}<br/>" +
      "<b>User:</b>\t#{pt.user.name}<br/>" +
      "<b>Comment:</b>\t#{pt.comment}"

    this.show_detail html
  end

  column :name do |c|
    c.flex	= 1
  end

  column :created_dt do |c|
    c.text	= "Date/Time"
    c.format	= "Y-m-d H:i"
    c.hidden	= true
  end

  column :user__name do |c|
    c.width	= 100
  end

  column :comment do |c|
    c.width	= 100
  end

end

TagGrid = Marty::TagGrid
