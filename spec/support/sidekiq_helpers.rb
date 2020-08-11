require 'timeout'

module Marty::RSpec::SidekiqHelpers
  def log_path
    Rails.root.join('log', 'sidekiq_test.log')
  end

  def start_sidekiq
    File.delete(log_path) if File.exist?(log_path)

    Thread.new do
      `cd #{Rails.root} && RAILS_EAGER_LOAD=true RAILS_ENV=test bundle exec sidekiq -e test -c 8 2>&1 >./log/sidekiq_test.log`
    end

    sleep 5

    begin
      sidekiq_pid = pid
    rescue => e
      raise "Couldn't find sidekiq pid in #{log_path}"
    end
    binding.pry if sidekiq_pid.blank?
    raise "Couldn't find sidekiq pid in #{log_path}" if sidekiq_pid.blank?

    ENV['__sidekiq_pid'] = sidekiq_pid
    # line_with_pid = File.open(Rails.root.join('log', 'sidekiq_test.txt'), &:readline)
    # pid = line_with_pid.split(' ').find { |text| text.include?('pid=') }.sub('pid=', '')
    # puts 'started 1'
    # puts "sidekiq started with pid: #{pid}"
  end

  def pid
    read_pid = lambda do
      begin
        line_with_pid = File.open(log_path) do |f|
          line = f.readline
          f.close
          line
        end
        line_with_pid.split(' ').find { |text| text.include?('pid=') }.sub('pid=', '')
      rescue => e
      end
    end

    Timeout::timeout(5) do
      while true
        pid_str = read_pid.call
        return pid_str if pid_str.present?
        sleep 1
      end
    end
  end

  def stop_sidekiq
    Process.kill('SIGTERM', ENV['__sidekiq_pid'].to_i)
    ENV.delete('__sidekiq_pid')
    sleep 4
  end
end
