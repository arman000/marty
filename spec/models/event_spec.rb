require 'spec_helper'
require 'marty'

describe Marty::Event do
  before(:all) do
    @clean_file = "/tmp/clean_#{Process.pid}.psql"
    save_clean_db(@clean_file)
    self.use_transactional_fixtures = false
    Mcfly.whodunnit = UserHelpers.system_user

    # add events
    Marty::Event.create!(klass: 'testclass',
                         subject_id: 123,
                         start_dt: Time.zone.parse('2016-07-15 08:00:00'))
    Marty::Event.create!(klass: 'testclass',
                         subject_id: 123,
                         start_dt: Time.zone.parse('2016-07-15 08:15:00'),
                         expire_secs: 60)
    Marty::Event.create!(klass: 'testclass2',
                         subject_id: 10,
                         start_dt: Time.zone.parse('2016-07-15 09:00:00'),
                         end_dt: Time.zone.parse('2016-07-15 09:10:00'))

    #with promise?


    # add model for enum_event_operation for spec dummy app
    # and migration 
  end

  after(:each) do
    Timecop.return
  end

  after(:all) do
    self.use_transactional_fixtures = true
    restore_clean_db(@clean_file)
  end

  it "does" do
    binding.pry
  end
end
=begin

test op_is_running?
test lookup_event
test finish_event
test last_event
test currently_running
=end
