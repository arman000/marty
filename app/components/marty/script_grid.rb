require 'zip'

class Marty::ScriptGrid < Marty::Grid
  has_marty_permissions \
    create: [:dev],
    read: :any,
    update: [:dev],
    delete: [:dev]

  def configure(c)
    super

    c.model                  = 'Marty::Script'
    c.multi_select           = false
    c.attributes ||= [:name, :created_dt, :tag]
    c.title ||= I18n.t('scripts', default: 'Scripts')
    c.store_config.merge!(sorters: [{ property: :name, direction: 'ASC' }])
  end

  def get_records(params)
    begin
      ts = Marty::Tag.map_to_tag(root_sess[:selected_tag_id]).created_dt
      ts = Mcfly.normalize_infinity(ts)
    rescue StandardError
      # if there are no non-DEV tags we get an exception above
      ts = 'infinity'
    end

    tb = model.table_name
    model.where("#{tb}.obsoleted_dt >= ? AND #{tb}.created_dt < ?",
                ts, ts).scoping do
      super
    end
  end

  action :delete do |a|
    a.text     = I18n.t('script_grid.delete')
    a.tooltip  = I18n.t('script_grid.delete')
    a.icon_cls = 'fa fa-trash glyph'
    a.disabled = config[:prohibit_delete]
  end

  endpoint :destroy do |params|
    return client.netzke_notify('Permission Denied') if
      !config[:permissions][:delete]

    tag = Marty::Tag.map_to_tag(root_sess[:selected_tag_id])

    return client.netzke_notify('Can only delete in DEV tag') unless
      tag && tag.isdev?

    super(params)
  end

  # override the add_in_form endpoint.  Script creation needs to use
  # the create_script method.
  endpoint :add_window__add_form__submit do |params|
    data = ActiveSupport::JSON.decode(params[:data])

    return client.netzke_notify('Permission Denied') if
      !config[:permissions][:create]

    tag = Marty::Tag.map_to_tag(root_sess[:selected_tag_id])

    return client.netzke_notify('Can only add in DEV tag') unless
      tag && tag.isdev?

    name = data['name']
    script = Marty::Script.create_script(name, "# Script #{name}")

    if script.valid?
      client.success = true
      return client.netzke_on_submit_success
    end

    client.netzke_notify(model_adapter.errors_array(script).join("\n"))
  end

  action :add_in_form do |a|
    a.text     = I18n.t('script_grid.new')
    a.tooltip  = I18n.t('script_grid.new')
    a.icon_cls = 'fa fa-plus glyph'
    a.disabled = !config[:permissions][:create]
  end

  def default_bbar
    [:add_in_form, :delete]
  end

  def default_context_menu
    []
  end

  def default_form_items
    [:name]
  end

  attribute :name do |c|
    c.flex      = 1
    c.text      = I18n.t('script_grid.name')
  end

  attribute :created_dt do |c|
    c.text      = I18n.t('script_grid.created_dt')
    c.format    = 'Y-m-d H:i'
    c.read_only = true
  end

  attribute :tag do |c|
    c.text      = I18n.t('script_grid.tag')
    c.flex      = 1
    c.getter    = lambda { |r| r.find_tag.try(:name) }
  end

  endpoint :upload_zip do |_zip_name, data64|
    begin
      next client.netzke_notify 'Permission Denied' unless
        config[:permissions][:create]

      rawdata64 = data64.sub(/data:.*;base64,/, '')
      data = Base64.decode64(rawdata64)

      status = []
      Zip::ZipInputStream.open(StringIO.new(data)) do |io|
        while (entry = io.get_next_entry)
          script_full = entry.name.split('/')
          script_name = script_full.pop

          script_path = if script_full.first == 'delorean'
                          script_full[1..-1]
                        else
                          script_full
                        end
          script_lhs = script_path.map(&:camelize).join('::')
          next unless script_name.ends_with?('.dl')

          script_name_final = script_name.sub(/.dl$/, '').camelize
          script_full_final = if script_lhs.present?
                                "#{script_lhs}::#{script_name_final}"
                              else
                                script_name_final
                              end
          script_body = entry.get_input_stream.read
          body_lines = script_body.lines.each_with_index.map do |line, ind|
            [ind, line.chomp]
          end

          begin
            # check syntax
            dev = Marty::Tag.find_by(name: 'DEV')
            Marty::ScriptSet.new(dev).parse_check(script_full_final, script_body)

            Marty::Script.load_a_script(script_full_final, script_body)
            status << "#{script_full_final} was loaded."
          rescue Delorean::ParseError => e
            Marty::Logger.error(name, {
                                  error: e.message,
                                  line: e.line,
                                  script: script_name_final,
                                  body_lines: body_lines
                                })
            status <<
              "#{script_full_final} parsing error: #{e.message} line: #{e.line}"
          rescue StandardError => e
            Marty::Logger.error(name, {
                                  error: e.message,
                                  script: script_name_final,
                                  body_lines: body_lines,
                                  stack: e.backtrace.select do |str|
                                    str.include?('script_grid')
                                  end
                                })
            status << "#{script_full_final} error: #{e.message}"
          end
        end
      end

      Marty::Logger.info(name, {
                           status: status
                         })
      client.netzke_notify status.join("<br>\n")
      client.reload
    end
  end
end

ScriptGrid = Marty::ScriptGrid
