require 'spec_helper'

describe Marty::Diagnostic::Base do
  def sample_data consistent=true
    node_data_a = Marty::Diagnostic::Base.pack(include_ip=false){'A'}
    node_data_b = Marty::Diagnostic::Base.pack(include_ip=false){'B'}

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

    expect(Marty::Diagnostic::Base.consistent?(a)).to eq(true)
    expect(Marty::Diagnostic::Base.consistent?(b)).to eq(false)
  end

  it 'can produce a valid diagnostic hash from a String' do
    expected = {
      'Base' => {
        'description' => 'A',
        'status' => true,
        'consistent' => nil
      }
    }

    expect(Marty::Diagnostic::Base.pack(include_ip=false){'A'}).to eq(expected)
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

    expect(Marty::Diagnostic::Base.
             pack(include_ip=false){test_a}).to eq(expected)
    expect(Marty::Diagnostic::Base.
             pack(include_ip=false){test_a}).to eq(expected)
  end

  it 'can produce a valid diagnostic hash from an error Hash' do
    test = Marty::Diagnostic::Base.pack(include_ip=false){
      Marty::Diagnostic::Base.error('E')
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
      'ImportantC' => Marty::Diagnostic::Base.create_info('C') + {
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

    expect{Marty::Diagnostic::Base.pack{test_a}}.to raise_error(RuntimeError)
    expect{Marty::Diagnostic::Base.pack{test_b}}.to raise_error(RuntimeError)
  end
end
