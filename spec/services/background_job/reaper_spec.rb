require 'spec_helper'

module Marty
  describe BackgroundJob::Reaper do
    context '#call' do
      it 'when inside the maintenance window, it without error' do
        allow(Marty::MaintenanceWindow).to receive(:call)
        res = described_class.call
        expect(res).to match(/trying to stop process/)
        expect(res).to match(/Starting.../)
      end
    end
  end
end
