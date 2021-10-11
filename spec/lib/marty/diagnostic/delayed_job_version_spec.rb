require 'job_helper'

describe Marty::Diagnostic::DelayedJobVersion do
  before(:each) do
    Marty::Script.load_scripts(nil, Time.zone.today)
  end

  def sample_data
    {
      Marty::Helper.my_ip => {
        'Version' => {
          'description' => Marty::VERSION,
          'status'      => true,
          'consistent'  => nil
        },
      }
    }
  end

  it 'can detect if all workers are running correct application version' do
    Rails.application.config.marty.diagnostic_app_version = Marty::VERSION
    start_delayed_job
    expect(described_class.generate).to eq(sample_data)
    stop_delayed_job
  end
end
