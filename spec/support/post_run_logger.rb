module Marty; module RSpec; module PostRunLogger
  class Storage
    def self.data
      @@data ||= []
    end

    def self.test_number
      @@num ||= 0
      @@num += 1
    end

    def self.store_data(name, line)
      data << "  #{test_number}) #{name}"
      data << Array(line).map { |string| "     #{string}" }
      data << ""
    end

    def self.dump_data
      unless data.empty?
        puts "\n\nPost Run Logging:\n\n"
        puts data
      end
    end
  end

  def post_run_log(*log_string)
    Storage.store_data example.example_group.parent_groups.map(&:description)
                         .reverse.join(' ') + ' ' + example.description,
                       log_string
  end
end end end
