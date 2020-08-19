require 'spec_helper'

module Marty
  describe BackgroundJob::Reaper do
    context '#call' do
      it 'when inside the maintenance window, it without error' do
        allow(Marty::MaintenanceWindow).to receive(:call)

        # in our AWS configuration, we expect that Apache runs Delayed Jobs
        # with root permissions for the delayed jobs commands.
        # Locally and in CI that is not the case so we remove the sudo -i
        allow_any_instance_of(Marty::MainAuthApp).to receive(
          :bg_command).and_return(
            "export RAILS_ENV=test; #{Rails.root.join('bin/delayed_job')}"\
            ' restart -n 1 --sleep-delay 5 2>&1'
          )
        expect(described_class.call).to match(/Starting.../)
      end
    end
  end
end
