module Marty
  module ComponentUtil
    def self.extended(klass)
      klass.client_class do |c|
        c.include :component_util
      end
    end

    def self.simple_html_table_gen(what, data)
      return "No #{what}" if data.blank?

      xm = Builder::XmlMarkup.new(indent: 2)
      xm.style(
        'table.simple_popup { border-spacing: 10px 10px; }
         tr.simple_popup_gray { background-color: rgb(220,220,220); }
         td.simple_popup { padding: 5px 20px 5px 20px; }'
      )
      xm.table(class: 'simple_popup') do
        xm.tr { data[0].keys.each { |key| xm.th(key, class: 'simple_popup') } }
        data.each do |row|
          xm.tr do
            row.values.each do |value|
              xm.td(value, class: 'simple_popup')
            end
          end
        end
      end
      xm.target!
    end
  end
end
