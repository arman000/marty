require 'spec_helper'
require 'marty/background_job/schedule'

module Marty
  module BackgroundJob
    describe Schedule do
      let(:subject) do
        described_class.new(job_class: 'TestJob', cron: '* * * * *', state: 'on')
      end

      VALID_CRONS = [
        '* * * * *',
        '45 23 * * 6',
        '0 7,17 * * *',
        '0 17 * * 6',
        '*/10 * * * *',
        '30 10 * * *',
        '0 * * * *',
        '0 * * * *',
      ].freeze

      INVALID_CRONS = [
        'text 23 * * 6',
        '1',
        '* * *'
      ].freeze

      it 'valid with valid cron expression' do
        VALID_CRONS.each do |cron|
          subject.cron = cron
          expect(subject).to be_valid
        end
      end

      it 'invalid with valid cron expression' do
        INVALID_CRONS.each do |cron|
          subject.cron = cron
          expect(subject).to_not be_valid
        end
      end
    end
  end
end
