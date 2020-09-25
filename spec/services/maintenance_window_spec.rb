require 'spec_helper'

module Marty
  describe MaintenanceWindow do
    let(:config_key) { 'SPEC_MAINT_WINDOW' }
    before(:each) do
      Marty::Config[config_key] = {
        'day' => 'Saturday',
        'range' => ['01:00', '24:00']
      }
    end

    after(:each) { Timecop.return }

    context '#call' do
      it 'requires day to be a valid dayname' do
        Marty::Config[config_key] = {
          'day' => 'Sat',
          'range' => ['00:00', '24:00']
        }
        expect { described_class.call(config_key) }.to raise_error(/valid day/)
      end

      it 'allows day to be all using *' do
        Marty::Config[config_key] = {
          'day' => '*',
        'range' => ['00:00', '24:00']
        }
        expect { described_class.call(config_key) }.not_to raise_error
      end

      it 'refuses to run if today is not the maintenance day' do
        Timecop.freeze(Time.zone.now.next_occurring(:friday).middle_of_day)
        expect { described_class.call(config_key) }.to raise_error(/can only be called on/)
      end

      it 'refuses to run if current time not withing maintenance window' do
        Timecop.freeze(Time.zone.now.next_occurring(:saturday).midnight)
        expect { described_class.call(config_key) }.to raise_error(
          /time not within maintenance window/)
      end
    end
  end
end
