require 'spec_helper'

describe Marty::Diagnostic::Collection do
  def sample_data consistent = true
    node_a_data = Marty::Diagnostic::Collection.pack(include_ip=false){'A'}
    data = {
      'NodeA' => node_a_data,
      'NodeB' => node_a_data,
    }
    return data if consistent
    data + {'NodeB' => {'Base' => Marty::Diagnostic::Collection.error('B')}}
  end

  it 'all diagnostics in diagnostics class attribute are generated' do
    diags = [Marty::Diagnostic::Version, Marty::Diagnostic::Nodes]
    expected = diags.map{|d| d.generate}.reduce(:deep_merge)
    Marty::Diagnostic::Collection.diagnostics = diags
    expect(Marty::Diagnostic::Collection.generate).to eq(expected)
  end

  it 'declares data consistency via status consistency' do
    a = sample_data
    b = sample_data + {
      'NodeB' => Marty::Diagnostic::Collection.pack(include_ip=false){'B'}
    }
    c = sample_data(consistent=false)

    expect(Marty::Diagnostic::Collection.consistent?(a)).to eq(true)
    expect(Marty::Diagnostic::Collection.consistent?(b)).to eq(true)
    expect(Marty::Diagnostic::Collection.consistent?(c)).to eq(false)
  end
end
