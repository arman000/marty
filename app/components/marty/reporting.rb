class Marty::Reporting < Netzke::Base
  def configure(c)
    super
    c.items = [
               :select_report,
               :report_form,
              ]
  end

  js_configure do |c|
    c.header   = false
    c.layout   = :border
    c.defaults = {body_style: 'padding:0px'}

    c.select_report = <<-JS
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

  component :select_report do |c|
    c.klass  = Marty::SelectReport
    c.split  = true
    c.region = :west
    c.width  = 300
  end
end

Reporting = Marty::Reporting
