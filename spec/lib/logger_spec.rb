require 'spec_helper'
require 'job_helper'

module Marty
  describe Logger do
    before(:all) do
      self.use_transactional_tests = false
    end
    before(:each) do
      Marty::Log.delete_all
    end
    after(:all) do
      Marty::Log.delete_all
      self.use_transactional_tests = true
    end

    it "log has its own connection" do
      expect(Marty::Log.connection).not_to equal(Marty::Posting.connection)
      expect(Marty::Posting.connection).to equal(Marty::Script.connection)
    end

    it "logs" do
      info_s = {'info' => 'message'}
      error_s = [1, 2, 3, {'error' =>'message'}]
      fatal_s = ["string", 123, {'fatal' => "message",
                                 'another_key' => 'value'}]
      Marty::Logger.info('info message', info_s)
      Marty::Logger.error('error message', error_s)
      Marty::Logger.fatal('fatal message', fatal_s)
      log = Marty::Log.all
      log_detail = log.map{|l| [l[:message_type], l[:message], l[:details]]}
      log_ts = log.map{|l| l[:timestamp]}
      expect(log_detail[0]).to eq(["info", "info message", info_s])
      expect(log_detail[1]).to eq(["error", "error message", error_s])
      expect(log_detail[2]).to eq(["fatal", "fatal message", fatal_s])
      log_ts.each do |ts|
        expect(ts.to_i).to be_within(5).of(Time.zone.now.to_i)
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
      expect(log.details).to eq({ "message" => the_error,
                                  "data" => JSON.parse(data.to_json)})
    end
  end

  describe "Exercise" do
    before(:all) do
      @clean_file = "/tmp/clean_#{Process.pid}.psql"
      save_clean_db(@clean_file)
      # transactional fixtures interfere with queueing jobs
      self.use_transactional_tests = false
      Marty::Log.cleanup(0)

      # Needed here because shutting transactional fixtures off
      # means we lose the globally set user
      Mcfly.whodunnit = system_user

      Marty::Script.load_script_bodies(promise_bodies, Date.today)
      start_delayed_job
    end

    after(:all) do
      restore_clean_db(@clean_file)
      stop_delayed_job
      File.unlink("/tmp/logaction.txt")
      Marty::Log.cleanup(0)
      self.use_transactional_tests = true
    end

    it "handles heavy load" do
      File.open(Rails.root.join("log/test.log")) do |f|
        f.seek(0, IO::SEEK_END)
        engine = Marty::ScriptSet.new.get_engine(NAME_K)

        res = (1..1000).map do |i|
          engine.background_eval("LOGGER", {"msgid" => i}, ["result"])
        end

        # wait for all the jobs to finish; collect/check their result
        expect(res.map {|x| x["result"]}.sort).to eq (1..1000).to_a

        line_count = File.readlines("/tmp/logaction.txt").count

        log_count = Marty::Log.all.count
        failed_count = f.readlines.select do
          |l|
          l == "Marty::Logger failure: database is locked\n"
        end.count

        expect(Marty::Promise.where.not(result: {}).count).to eq 1000

        # each background_eval writes one line to /tmp/logaction.txt
        # these must happen no matter what happens in Marty::Logger
        expect(line_count).to eq(1000)

        # each background_eval does 10 calls to Marty::Logger.
        # failures (after 3 retries at 0.1 sec each) are logged to rails log
        # the total count should be 10000
        expect(log_count + failed_count).to eq(10000)
      end
    end
  end
end
