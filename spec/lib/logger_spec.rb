require 'spec_helper'

module Marty
  describe Logger do
    before(:all) do
      self.use_transactional_fixtures = false
    end
    before(:each) do
      @db =  SQLite3::Database.new(Marty::Log.logfile)
    end
    after(:each) do
      @db.execute "delete from log"
      @db.close
    end
    after(:all) do
      self.use_transactional_fixtures = true
    end

    it "logs" do
      File.open(Rails.root.join("log/test.log")) do |f|
        f.seek(0, IO::SEEK_END)
        info_s = { info: 'message' }
        error_s = [1, 2, 3, { error: 'message' }]
        fatal_s = ["string", 123, { fatal: "message", another_key: 'value' }]
        Marty::Logger.info('info message', info_s)
        Marty::Logger.error('error message', error_s)
        Marty::Logger.fatal('fatal message', fatal_s)
        rails_log = f.readlines
        log = @db.execute "select * from log"
        log_detail = []
        log_ts = []
        log.each do |l|
          id, type, msg, ts, detail_str = l
          log_detail[id] = [type, msg, detail_str]
          log_ts[id] = ts
        end
        expect(rails_log).to eq(["info message\n",
                                 "error message\n",
                                 "fatal message\n"])
        expect(log_detail[1]).to eq(["info", "info message",
                                     info_s.pretty_inspect])
        expect(log_detail[2]).to eq(["error", "error message",
                                     error_s.pretty_inspect])
        expect(log_detail[3]).to eq(["fatal", "fatal message",
                                     fatal_s.pretty_inspect])
        (1..3).each do |idx|
          expect(log_ts[idx]).to be_within(5).of(Time.zone.now.to_i)
        end
      end
    end
    it "with_logging" do
      bd = 'block description'
      the_error = 'error during my block'
      data = [1, 2, 3, Marty::User.first]
      begin
        Marty::Logger.with_logging(bd, data) do
          raise the_error
        end
      rescue => e
        raised = e.message
      end
      expect(raised).to eq("#{bd}: #{the_error}")
      log = Marty::Log.first
      expect(log.message_type).to eq('error')
      expect(log.message).to eq(bd)
      expect(log.details).to eq({ message: the_error,
                                  data: data }.pretty_inspect)
    end
  end
  describe "Logger errors" do
    it "fails gracefully" do
      allow(Marty::Log).to receive(:db_init).
                            and_raise("Error initializing DB")
      Marty::Log.instance_variable_set(:@db, nil)
      File.open(Rails.root.join("log/test.log")) do |f|
        f.seek(0, IO::SEEK_END)
        expect{Marty::Logger.info('info message', [1,2,3])}.not_to raise_error
        rails_log = f.readlines
        expect(rails_log).to eq(["info message\n",
                                 "Marty::Logger failure: Error initializing DB\n"])
      end
    end
    it "fails gracefully in ensure" do
      Marty::Logger.info('init db', [])
      close_err = 'Error closing statement'
      allow_any_instance_of(SQLite3::Statement).to receive(:close).
                                                   and_raise(close_err)
      File.open(Rails.root.join("log/test.log")) do |f|
        f.seek(0, IO::SEEK_END)
        expect{Marty::Logger.info('ensure message', [1,2,3])}.not_to raise_error
        rails_log = f.readlines
        expect(rails_log).to eq(["ensure message\n"])
        allow_any_instance_of(SQLite3::Statement).to receive(:close).
                                                      and_call_original
        sleep 1
        Marty::Log.cleanup(0)
      end
    end
  end
end
