require 'spec_helper'

module Marty
  describe DataConversion do
    describe '#convert' do
      describe 'date' do
        let(:date) { 1.day.ago.to_date }

        it 'converts float strings to date' do
          res = described_class.convert('40000.0', :date)
          expect(res).to eq Date.new(2009, 7, 6)
        end

        it 'converts date to date' do
          res = described_class.convert(date, :date)
          expect(res).to eq date
        end

        it 'converts infinity' do
          ['Infinity', 'infinity', ::Float::INFINITY].each do |value|
            res = described_class.convert(value, :date)
            expect(res).to eq 'infinity'
          end
        end

        it 'raises error if the value is not valid' do
          expect { described_class.convert(true, :date) }.
            to raise_error(/date conversion failed for true/)
        end
      end

      describe 'boolean' do
        it 'converts true' do
          ['true', '1', 'y', 't'].each do |value|
            res = described_class.convert(value, :boolean)
            expect(res).to eq true
          end
        end

        it 'converts false' do
          ['false', '0', 'n', 'f'].each do |value|
            res = described_class.convert(value, :boolean)
            expect(res).to eq false
          end
        end

        it 'raises error if the value is not valid' do
          expect { described_class.convert(1.day.ago, :boolean) }.
            to raise_error(/unknown boolean/)
        end
      end
    end
  end
end
