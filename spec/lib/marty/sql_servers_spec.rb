require 'marty/sql_servers'

RSpec.describe Marty::SqlServers do
  it 'has an instance variable called @clients' do
    internal_clients = subject.instance_variable_get(:@clients)
    expect(internal_clients).to be_a(ActiveSupport::HashWithIndifferentAccess)
  end

  it 'aliases the SqlServers module in the application namespace' do
    expect(Dummy::SqlServers).to eq(described_class)
  end
end
