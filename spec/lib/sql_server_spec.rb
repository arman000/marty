module Marty
  describe SqlServer do
    let(:server_name) { 'SQLSERVER_' }
    let(:exec_command) do
      Rails.configuration.
        database_configuration[server_name + Rails.env].
        dig('test_command')
    end

    context 'while mocked' do
      describe '#connection' do
        context 'in block' do
          context 'when returning a TinyTds::Result' do
            it 'works when running single query' do
              res = Marty::SqlServer.with_connection(server_name) do |conn|
                conn.execute('SELECT 1 as juan')
              end
              expect(res).to eq([{ 'juan' => 1 }])
            end

            it 'works when running many queries in one statement' do
              res = Marty::SqlServer.with_connection(server_name) do |conn|
                conn.execute('SELECT 1 as juan; SELECT 2 as juan; SELECT 3 as juan')
              end
              expect(res).to eq([[{ 'juan' => 1 }], [{ 'juan' => 2 }], [{ 'juan' => 3 }]])
            end

            it 'works when running many queries in one block' do
              res = Marty::SqlServer.with_connection(server_name) do |conn|
                conn.execute('SELECT 1 as juan')
                conn.execute('SELECT 2 as juan')
                conn.execute('SELECT 3 as juan')
              end
              expect(res).to eq([{ 'juan' => 3 }])
            end

            it 'properly stubs out multiple calls in one spec' do
              res1 = Marty::SqlServer.with_connection(server_name) do |conn|
                conn.execute('SELECT 0 as zero')
                conn.execute('SELECT 1 as juan')
              end
              res2 = Marty::SqlServer.with_connection(server_name) do |conn|
                conn.execute('SELECT 2 as duex')
              end
              res3 = Marty::SqlServer.with_connection(server_name) do |conn|
                conn.execute('SELECT 3 as tres')
              end
              expect(res1).to eq([{ 'juan' => 1 }])
              expect(res2).to eq([{ 'duex' => 2 }])
              expect(res3).to eq([{ 'tres' => 3 }])
            end

            it "doesn't fail if you try to reuse a connection without handling results" do
              expect do
                Marty::SqlServer.with_connection(server_name) do |conn|
                  conn.execute('SELECT 1 as juan')
                  conn.execute('SELECT 2 as juan')
                end
              end.to_not raise_error
            end
          end

          context 'when returning non-TinyTds::Result' do
            it 'works when returning null' do
              res = Marty::SqlServer.with_connection(server_name) do |conn|
                conn.execute('SELECT 1 as juan').first.dig('rodez')
              end
              expect(res).to be_nil
            end

            it 'works when returning an Array of not Hashes' do
              res = Marty::SqlServer.with_connection(server_name) do |_conn|
                [1, 2, 3]
              end
              expect(res).to eq([1, 2, 3])
            end

            it 'works when returning non-Enumerable' do
              res = Marty::SqlServer.with_connection(server_name) do |conn|
                conn.execute('SELECT 1 as juan').first.dig('juan')
              end
              expect(res).to eq(1)
            end
          end
        end

        it 'works without block' do
          # Our stubs aren't really setup to stub a connection right now
          # they are intended to stub query results so there is no cassette
          # for this if you try to run it outside of REGEN
          skip 'Only works in REGEN' unless ENV['REGEN'] == 'true'

          res = described_class.connection(server_name)
          expect(res).to be_a(Marty::SqlServer::Connection)
          expect(res.client).to be_a(TinyTds::Client)
        end
      end

      describe '#exec_query' do
        it 'works with select' do
          res = described_class.exec_query(server_name, 'SELECT 1 as juan')
          expect(res).to eq([{ 'juan' => 1 }])
        end

        it 'properly stubs out multiple calls in one spec' do
          res1 = described_class.exec_query(server_name, 'SELECT 1 as juan')
          res2 = described_class.exec_query(server_name, 'SELECT 2 as duex')
          expect(res1).to eq([{ 'juan' => 1 }])
          expect(res2).to eq([{ 'duex' => 2 }])
        end

        it 'works with exec' do
          skip 'No test command provided' if exec_command.nil?
          res = described_class.exec_query(
            server_name, exec_command)
          expect(res).to be_an(Array)
        end

        context 'testing deep' do
          context 'context stubs' do
            it 'work' do
              res = described_class.exec_query(server_name, 'SELECT 1 as juan')
              expect(res).to eq([{ 'juan' => 1 }])
            end
          end
        end
      end
    end

    context 'while unmocked' do
      before(:all) { @regen = ENV['REGEN'] }
      before(:each) { ENV['REGEN'] = 'true' }
      after(:each) { ENV['REGEN'] = @regen }

      describe 'Error' do
        it 'will raise DatabaseConfigurationError if bad config' do
          expect do
            described_class.connection('QWERTY_')
          end.to raise_error(SqlServer::Errors::DatabaseConfigurationError)
        end

        it 'will raise ConnectionNotEstablishedError if connection fails' do
          skip 'No test endpoint configured' unless
            Rails.configuration.database_configuration['SQLSERVER_' + Rails.env]['host']
          allow_any_instance_of(TinyTds::Client).to receive(:active?).and_return(false)

          expect do
            described_class.connection(server_name)
          end.to raise_error(SqlServer::Errors::ConnectionNotEstablishedError)
        end
      end
    end
  end
end
