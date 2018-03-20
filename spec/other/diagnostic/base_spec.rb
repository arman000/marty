require 'spec_helper'

describe Marty::Diagnostic::Base do
  def sample_data consistent=true
    node_data_a = described_class.pack(include_ip=false){'A'}
    node_data_b = described_class.pack(include_ip=false){'B'}

    data = {
      'NodeA' => node_data_a,
      'NodeB' => node_data_a,
    }

    return data if consistent
    data + {'NodeB' => node_data_b}
  end

  it 'determines consistency of aggregate diagnostics' do
    a = sample_data
    b = sample_data(consistent=false)

    expect(described_class.consistent?(a)).to eq(true)
    expect(described_class.consistent?(b)).to eq(false)
  end

  it 'can produce a valid diagnostic hash from a String' do
    expected = {
      'Base' => {
        'description' => 'A',
        'status' => true,
        'consistent' => nil
      }
    }

    expect(described_class.pack(include_ip=false){'A'}).to eq(expected)
  end

  it 'can produce a valid diagnostic hash from a Hash' do
    test_a = {
      'ImportantA' => 'A',
      'ImportantB' => 'B',
      'ImportantC' => 'C'}

    test_b = {
      'ImportantA' => {
        'description' => 'A', 'status' => true, 'consistent' => nil},
      'ImportantB' => 'B',
      'ImportantC' => 'C'}

    expected = {
      'ImportantA' => {
        'description' => 'A', 'status' => true, 'consistent' => nil
      },
      'ImportantB' => {
        'description' => 'B', 'status' => true, 'consistent' => nil
      },
      'ImportantC' => {
        'description' => 'C', 'status' => true, 'consistent' => nil
      },
    }

    expect(described_class.
             pack(include_ip=false){test_a}).to eq(expected)
    expect(described_class.
             pack(include_ip=false){test_a}).to eq(expected)
  end

  it 'can produce a valid diagnostic hash from an error Hash' do
    test = described_class.pack(include_ip=false){
      described_class.error('E')
    }

    expected = {
      "Base"=>{
        "description"=>"E",
        "status"=>false,
        "consistent"=>nil}
    }

    expect(test).to eq(expected)
  end

  it 'will raise an error if Hash is invalid.' do
    test_a = {
      'ImportantA' => 'A',
      'ImportantB' => 'B',
      'ImportantC' => described_class.create_info('C') + {
        'extra' => 'D'
      }
    }

    test_b = {
      'Test' => {
        'ImportantA' => 'A',
        'ImportantB' => 'B',
        'ImportantC' => 'C',
      }
    }

    expect{described_class.pack{test_a}}.to raise_error(RuntimeError)
    expect{described_class.pack{test_b}}.to raise_error(RuntimeError)
  end
end
