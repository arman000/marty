module Marty
  describe Posting do
    describe 'validations' do
      it 'requires unique names' do
        dt = '20130215 0800'
        c = Posting.count
        Posting.do_create('BASE', dt, 'a comment')
        Posting.count.should == c + 1
        expect { s = Posting.do_create('BASE', dt, 'a comment') }.
          to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'creates name based on PDT' do
        d, t, tz = '20130215', '0900', 'PST8PDT'
        dt_tz = [d, t, tz].join(' ')
        p = Posting.do_create('BASE', dt_tz, 'a comment')
        expect(p.name).to match /BASE-#{d}-#{t}/
        p.reload
        expect(p.created_dt).to eq Time.zone.parse(dt_tz)
      end
    end

    describe 'lookups' do
      it 'are seeded with a NOW posting' do
        expect(Posting.lookup_dt('NOW')).to eq Float::INFINITY
      end

      describe '.get_latest_by_type' do
        context 'when invalid parameters are supplied' do
          it "raises 'posting type list missing' error" do
            expect { Posting.get_latest_by_type(10, nil) }.
              to raise_error 'missing posting types list'
          end

          it "raises 'bad posting types list' error" do
            expect { Posting.get_latest_by_type(10, 'BASE') }.
              to raise_error 'bad posting types list'
          end
        end

        context 'when valid parameters are supplied' do
          before do
            Posting.do_create('BASE',     0.days.from_now, 'base posting')
            Posting.do_create('SNAPSHOT', 1.day.from_now, 'snapshot1 posting')
            Posting.do_create('SNAPSHOT', 2.days.from_now, 'snapshot2 posting')
            Posting.do_create('OTHER', 3.days.from_now, 'other1 posting')
            Posting.do_create('SNAPSHOT', 4.days.from_now, 'snapshot3 posting')
            Posting.do_create('OTHER', 5.days.from_now, 'other2 posting')
          end

          it 'filters on a single posting type' do
            # First param is just the limit (max) to return
            res = Posting.get_latest_by_type(10, ['BASE'])
            expect(res.count).to eq 1
            r0 = Posting.find_by(name: res[0]['name'])
            expect(r0.comment).to eq 'base posting'
          end

          it 'filters on multiple posting types' do
            res = Posting.get_latest_by_type(10, ['BASE', 'SNAPSHOT'])
            expect(res.count).to eq 4
            # snapshot3 is most recent with this filter
            r0 = Posting.find_by(name: res[0]['name'])
            r3 = Posting.find_by(name: res[3]['name'])
            expect(r0.comment).to eq 'snapshot3 posting'
            expect(r3.comment).to eq 'base posting'
          end

          it 'filters on posting types that are single or double quoted' do
            res = Posting.get_latest_by_type(10, ['SNAPSHOT', 'OTHER'])
            expect(res.count).to eq 5
            # other2 is most recent with this filter
            r0 = Posting.find_by(name: res[0]['name'])
            r4 = Posting.find_by(name: res[4]['name'])
            expect(r0.comment).to eq 'other2 posting'
            expect(r4.comment).to eq 'snapshot1 posting'
          end

          it 'filters and limits on multiple posting types' do
            res = Posting.get_latest_by_type(3, ['SNAPSHOT', 'OTHER'])
            expect(res.count).to eq 3
            # other2 is most recent with this filter
            r0 = Posting.find_by(name: res[0]['name'])
            r2 = Posting.find_by(name: res[2]['name'])
            expect(r0.comment).to eq 'other2 posting'
            expect(r2.comment).to eq 'other1 posting'
          end

          it 'returns nothing with an empty posting type list' do
            res = Posting.get_latest_by_type(10, [])
            expect(res.count).to eq 0
          end
        end
      end
    end
  end
end
