require 'spec_helper'

RSpec.describe Marty::Rules::Retrieve do
  def call(name)
    # only name arg matters since we are stubbed
    described_class.download('host', 1234, 1234, name, Time.zone.now)
  end

  it 'retrieves rules packages' do
    data = JSON.parse(File.read(file_fixture('misc/rules/package_download.json')))
    allow(Marty::RpcCall).to receive(:json_call).and_return(data)

    call(data['name'])

    expect(Marty::Rules::Package.count).to eq(4)
    build = data['builds'][rand(data['builds'].count)]
    rec = Marty::Rules::Package.find_by(build_name: build['name'])

    expect(rec.name).to eq(data['name'])
    expect(rec.build_name).to eq(build['name'])
    expect(rec.metadata).to eq(build['metadata'])

    call(data['name'])
    expect(Marty::Rules::Package.count).to eq(4)
  end
end
