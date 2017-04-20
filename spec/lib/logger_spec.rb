require 'spec_helper'
require 'job_helper'

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
  describe "Exercise" do
    before(:all) do
      @clean_file = "/tmp/clean_#{Process.pid}.psql"
      save_clean_db(@clean_file)
      # transactional fixtures interfere with queueing jobs
      self.use_transactional_fixtures = false

      # Needed here because shutting transactional fixtures off
      # means we lose the globally set user
      Mcfly.whodunnit = UserHelpers.system_user

      Marty::Script.load_script_bodies(promise_bodies, Date.today)
      start_delayed_job
    end
    after(:all) do
      restore_clean_db(@clean_file)
      stop_delayed_job
      File.unlink("/tmp/logaction.txt")
      Marty::Log.cleanup(0)
      self.use_transactional_fixtures = true
    end

    it "handles heavy load" do
      File.open(Rails.root.join("log/test.log")) do |f|
        f.seek(0, IO::SEEK_END)
        engine = Marty::ScriptSet.new.get_engine(NAME_K)
        (1..1000).each do |i|
          engine.background_eval("LOGGER", {"msgid" => i}, ["result"])
        end

        60.times do
          running = Marty::Promise.uncached {
            Marty::Promise.unscoped.where(result: nil)
          }.count
          break if running == 0
          sleep 1
        end

        # each background_eval writes one line to /tmp/logaction.txt
        # these must happen no matter what happens in Marty::Logger
        expect(File.readlines("/tmp/logaction.txt").count).to eq(1000)

        # each background_eval does 10 calls to Marty::Logger.
        # failures (after 3 retries at 0.1 sec each) are logged to rails log
        # the total count should be 10000
        log_count = Marty::Log.all.count
        failed_count = f.readlines.select do
          |l|
          l == "Marty::Logger failure: database is locked\n"
        end.count
        expect(log_count + failed_count).to eq(10000)
      end
    end
  end
end
