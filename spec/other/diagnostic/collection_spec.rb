require 'spec_helper'

describe Marty::Diagnostic::Collection do
  def sample_data consistent = true
    node_a_data = described_class.pack(include_ip=false) {'A'}
    data = {
      'NodeA' => node_a_data,
      'NodeB' => node_a_data,
    }
    return data if consistent
    data + {'NodeB' => {'Base' => described_class.error('B')}}
  end

  it 'all diagnostics in diagnostics class attribute are generated' do
    diags = [Marty::Diagnostic::Version, Marty::Diagnostic::Nodes]
    expected = diags.map {|d| d.generate}.reduce(:deep_merge)
    described_class.diagnostics = diags
    expect(described_class.generate).to eq(expected)
  end

  it 'declares data consistency via status consistency' do
    a = sample_data
    b = sample_data + {
      'NodeB' => described_class.pack(include_ip=false) {'B'}
    }
    c = sample_data(consistent=false)

    expect(described_class.consistent?(a)).to eq(true)
    expect(described_class.consistent?(b)).to eq(true)
    expect(described_class.consistent?(c)).to eq(false)
  end
end
