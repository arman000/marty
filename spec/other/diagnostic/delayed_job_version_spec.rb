require 'spec_helper'
require 'job_helper'

describe Marty::Diagnostic::DelayedJobVersion do
  # used to stub request object
  class DummyRequest
    attr_accessor :params, :port
    def initialize
      @params = {}
    end
  end

  before(:each) do
    Marty::Script.load_scripts(nil, Date.today)
    allow(described_class).to receive(:scope).and_return(nil)
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
    ENV['DELAYED_VER'] = Marty::VERSION
    start_delayed_job
    expect(described_class.generate).to eq(sample_data)
    stop_delayed_job
  end

  it 'will fail if DELAYED_VER is not set' do
    ENV.delete('DELAYED_VER')
    start_delayed_job
    expect { described_class.generate }.to raise_error(RuntimeError)
    stop_delayed_job
  end
end
