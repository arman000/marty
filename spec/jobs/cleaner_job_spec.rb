require 'spec_helper'

module Marty
  describe CleanerJob do
    context '.perform' do
      it 'will create a promise for CleanAll.call' do
        allow(Cleaner::CleanAll).to receive(:call)
        subject = described_class.new
        subject.perform
        expect(Marty::Promise.last.title).to eq(
          'Marty::Cleaner::CleanAll.call'
        )
      end
    end
  end
end
