class Marty::PostingGrid < Marty::Grid
  has_marty_permissions read: :any,
                        delete: :any # delete is hijacked for a select

  def configure(c)
    super

    c.header             = false
    c.model              = "Marty::Posting"
    c.attributes = [:name, :created_dt, :user__name, :comment]
    c.multi_select = false
    c.store_config.merge!(sorters: [{ property: :created_dt, direction: 'DESC' }],
                           page_size: 12)
  end

  client_class do |c|
    c.include :posting_grid
  end

  # hijacking delete button
  action :delete do |a|
    a.text      = "Select"
    a.tooltip   = "Select"
    a.icon_cls  = "fa fa-clock glyph"
    a.disabled  = true
  end

  def default_bbar
    [:delete, :detail]
  end

  action :detail do |a|
    a.text      = "Detail"
    a.icon_cls  = "fa fa-th-large glyph"
    a.handler   = :detail
    a.disabled  = true
  end

  endpoint :detail do |params|
    record_id = params[:record_id]

    # Prepare an HTML popup with session details such that the
    # contents can be easily pasted into a spreadsheet.

    pt = Marty::Posting.find_by_id(record_id)

    dt = pt.created_dt.to_s == 'Infinity' ? '---' :
      pt.created_dt.strftime('%Y-%m-%d %I:%M %p')

    html =
      "<b>Name:</b>\t#{pt.name}<br/>" +
      "<b>Date/Time:</b>\t#{dt}<br/>" +
      "<b>User:</b>\t#{pt.user.name}<br/>" +
      "<b>Comment:</b>\t#{pt.comment}"

    client.netzke_show_detail html
  end

  attribute :name do |c|
    c.flex      = 1
  end

  attribute :created_dt do |c|
    c.text      = "Date/Time"
    c.format    = "Y-m-d H:i"
    c.hidden    = true
  end

  attribute :user__name do |c|
    c.width     = 100
  end

  attribute :comment do |c|
    c.width     = 100
  end
end

PostingGrid = Marty::PostingGrid
