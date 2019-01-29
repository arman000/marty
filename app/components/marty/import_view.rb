class Marty::ImportView < Marty::Form
  include Marty::Extras::Layout

  action :apply do |a|
    a.text    = I18n.t("data_import_view.import")
    a.tooltip = I18n.t("data_import_view.import")
    a.icon_cls = 'fa fa-database glyph'
  end

  def parent_model; end

  def import_model; end

  def model_view;   end

  def initialize args, kwargs
    super(args, kwargs)
    @model_view   = model_view.camelize.constantize   if model_view
    @parent_model = parent_model.camelize.constantize if parent_model
    @import_model = import_model.camelize.constantize if import_model
    @record       = nil
  end

  client_class do |c|
    c.include :import_view
  end

  ######################################################################

  def validate
    return client.netzke_notify("Must provide import data.") if
      @import_data.empty?
  end

  def process_additional_fields
    nil
  end

  def process_import_data
    CSV.new(@import_data, headers: true, col_sep: "\t")
  end

  def post_import
    nil
  end

  def import data
    Marty::DataImporter
      .do_import_summary(@import_model, data, 'infinity', nil, nil)
  end

  def format_message k, v
    case k
    when :clean  then "#{v} record(s) cleaned."
    when :same   then "#{v} record(s) unchanged."
    when :create then "#{v} record(s) created."
    when :update then "#{v} record(s) updated."
    when :blank  then "#{v} empty lines."
    end
  end

  endpoint :submit do |params|
    return client.netzke_notify "No Model View defined" unless @model_view

    return client.netzke_notify "Permission denied" unless
      @model_view.can_perform_action?(:update)

    return client.netzke_notify "Can't import when time-warped" if
      Marty::Util.warped?

    @data        = ActiveSupport::JSON.decode(params[:data])
    @import_data = @data["import_data"] || ""
    @record      = @parent_model.try(:find_by_id, client_config['parent_id'])

    validate                  and return
    process_additional_fields and return

    begin
      processed = process_import_data
      res       = import(processed)
      result    = res.map { |k, v| format_message(k, v) }

      messages  = post_import
      result << messages if messages

      client.set_result result.join("<br/>")
    rescue Marty::DataImporter::Error => exc
      result = [
        "Import failed on line(s): #{exc.lines.join(', ')}",
        "Error: #{exc.to_s}",
      ]

      client.set_result '<font color="red">' + result.join("<br/>") + "</font>"
    rescue => e
      client.set_result e.message
    end
  end

  def configure(c)
    super
    c.title = nil
    c.items =
      [
        textarea_field(:import_data,
                       height: 300,
                       hide_label: true,
                       min_width: 10000,
                      ),
        :result,
      ]
  end

  component :result do |c|
    c.klass       = Marty::Panel
    c.title       = I18n.t("data_import_view.results")
    c.html        = ""
    c.flex        = 1
    c.min_height  = 150
    c.scrollable = true
  end
end
