class Marty::Reporting < Netzke::Base
  def configure(c)
    super
    c.items = [
               :report_select,
               :report_form,
              ]
  end

  client_class do |c|
    c.header   = false
    c.layout   = :border
    c.defaults = {body_style: 'padding:0px'}

    c.select_report = l(<<-JS)
    function() {
       // this.netzkeGetComponent('report_form').netzkeLoad({});
       // FIXME: NetzkeReload() doesn't work when performed on
       // ReportForm. So, reload all of Reporting.
       this.netzkeReload();
    }
    JS
  end

  component :report_form do |c|
    c.klass  = Marty::ReportForm
    c.flex   = 1
    c.region = :center
  end

  component :report_select do |c|
    c.klass  = Marty::ReportSelect
    c.split  = true
    c.region = :west
    c.width  = 325
  end
end

Reporting = Marty::Reporting
