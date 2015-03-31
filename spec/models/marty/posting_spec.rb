require 'spec_helper'

module Marty
  describe Posting do
    before(:each) do
      Mcfly.whodunnit = Marty::User.create!(login: 'gemini', firstname: 'test', lastname: 'test', active: true)

      # FIXME: these two pre-seedings of the database should probably be handled differently
      PostingType.clear_lookup_cache!
      PostingType.seed
      create_now_posting
    end

    def create_now_posting
      unless Posting.find_by_name('NOW')
        sn                 = Posting.new
        sn.posting_type_id = PostingType["BASE"].id
        sn.comment         = '---'
        sn.created_dt      = 'infinity'
        sn.save!
      end
    end

    describe "validations" do
      it "should require unique Names" do
        dt = "20130215 0800"
        c = Posting.count
        Posting.do_create("BASE", dt, 'a comment')
        Posting.count.should == c + 1
        lambda {
          s = Posting.do_create("BASE", dt, 'a comment')
        }.should raise_error(ActiveRecord::RecordInvalid)
      end

      it "should create name based on PDT" do
        d, t, tz = "20130215", "0900", "PST8PDT"
        dt_tz = [d, t, tz].join(' ')
        p = Posting.do_create("BASE", dt_tz, 'a comment')
        p.name.should match /BASE-#{d}-#{t}/
        p.reload
        p.created_dt.should == Time.zone.parse(dt_tz)
      end
    end

    describe "lookups" do
      it "should be seeded with a NOW posting" do
        Posting.lookup_dt("NOW").should == Float::INFINITY
      end

      it "should provide list of latest of postings in descending order" do
        4.times { |d|
          Posting.do_create("BASE", d.day.from_now, 'a comment')
        }
        dt3 = 3.day.from_now

        latest = Posting.get_latest(1)
        latest.count.should == 1
        latest[0].name.should match /BASE-#{dt3.strftime("%Y%m%d-%H%M")}/
      end
    end
  end
end
