module Marty
  RSpec.describe ReportExecution, :focus do
    before do
      Marty::Script.load_scripts
      expect(described_class.any?).to eq(false)
    end

    let(:success_script) { 'EnumReport' }
    let(:success_report) { 'EnumValuesReport' }

    let(:failure_script) { 'DataReport' }
    let(:failure_report) { 'EnumReport' }

    let(:success_params) { testing_params(success_script, success_report) }
    let(:failure_params) { testing_params(failure_script, failure_report) }

    def submit_through_endpoint(params)
      subject = Marty::ReportForm.new
      subject.client = Netzke::Core::EndpointResponse.new
      subject.submit_endpoint(params)
    end

    def testing_params(script, node)
      ActionController::Parameters.new(
        {
          'data': {
            'selected_tag_id' => Marty::Tag.last.id,
            'selected_script_name' => script,
            'selected_node' => node,
          }.to_json,
        'reptitle': 'I M TESTING',
        'controller': 'marty/report',
        'action': 'index',
        'format': 'csv'
        }
      )
    end

    def check_report_execution(rpt_exec, report, is_error: false)
      aggregate_failures do
        expect(rpt_exec.report).to eq(report)
        expect(rpt_exec.error).to eq(is_error)
        expect(rpt_exec.completed_at).to be_present
      end
    end

    context 'foreground report execution' do
      it 'creates a complete record when succeeds' do
        Marty::ReportForm.run_eval(success_params)
        check_report_execution(described_class.last, success_report)
      end

      it 'creates a complete record when fails' do
        Marty::ReportForm.run_eval(failure_params)
        subject = described_class.last
        check_report_execution(subject, failure_report, is_error: true)
      end
    end

    context 'background report execution' do
      it 'creates a complete record when succeeds' do
        submit_through_endpoint(success_params)
        Delayed::Worker.new.work_off
        check_report_execution(described_class.last, success_report)
      end

      it 'creates a complete record when fails' do
        submit_through_endpoint(failure_params)
        Delayed::Worker.new.work_off
        subject = described_class.last
        check_report_execution(subject, failure_report, is_error: true)
      end
    end
  end
end
