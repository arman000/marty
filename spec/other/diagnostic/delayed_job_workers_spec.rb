require 'spec_helper'
require 'job_helper'

describe Marty::Diagnostic::DelayedJobWorkers do
  def sample_data opts = {}
    ip, error, status = opts.values_at(:ip, :error, :status)
    {
      ip || Marty::Helper.my_ip => {
        'Delayed Workers / Node' => {
          'description' => error ? '3' : '4',
          'status'      => status,
          'consistent'  => nil
        },
      }
    }
  end

  def sample_aggregate error = false
    [
      sample_data(ip: '0.0.0.0'),
      sample_data(ip: '0.0.0.1'),
      sample_data(ip: '0.0.0.2', error: error),
      sample_data(ip: '0.0.0.3'),
    ].reduce(:merge)
  end

  it 'can determine the number of workers on a node' do
    start_delayed_job
    expect(described_class.generate).to eq(sample_data)
    stop_delayed_job
  end

  it 'can determine if there are nodes with missing workers' do
    consistent   = sample_aggregate
    inconsistent = sample_aggregate(error = true)

    expect(described_class.consistent?(consistent)).to eq(true)
    expect(described_class.consistent?(inconsistent)).to eq(false)
  end

  it 'allows a config to set the target workers' do
    Marty::Config['DIAG_DELAYED_TARGET'] = 2
    start_delayed_job
    expect(described_class.generate).to eq(sample_data(status: false))
    stop_delayed_job
  end
end
