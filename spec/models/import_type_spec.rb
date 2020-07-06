require 'spec_helper'

module Marty
  class Marty::ARTestModel < ActiveRecord::Base
    def self.import_cleaner
    end

    def self.import_validator
    end
  end

  class Marty::TestModel
  end

  describe ImportType do
    let(:role) { Marty::RoleTypeAdapter.get_all.first }

    before(:each) do
      @import = ImportType.new
      @import.name = 'Test1'
      @import.db_model_name = 'Marty::ARTestModel'
      @import.role = role
      @import.save!
    end

    describe 'validations' do
      it 'require name, db_model and role' do
        it = ImportType.new
        expect(it).to_not be_valid
        expect(it.errors[:name].any?).to be true
        expect(it.errors[:db_model_name].any?).to be true
        expect(it.errors[:role].any?).to be true
      end

      it 'require a unique name' do
        it = ImportType.new
        it.name = 'Test1'
        it.db_model_name = 'Marty::ARTestModel'
        it.role = role
        expect(it).to_not be_valid
        expect(it.errors[:name].any?).to be true
      end

      it 'require an ActiveRecord model for the db_model_name' do
        it = ImportType.new
        it.name = 'Test1'
        it.db_model_name = 'Marty::TestModel'
        it.role = role
        expect(it).to_not be_valid
        expect(it.errors[:base][0]).to eq 'bad model name'
      end

      it 'do not fail on blank strings for functions' do
        @import.cleaner_function = ''
        @import.validation_function = ' '
        @import.preprocess_function = '  '

        expect(@import).to be_valid
        @import.save!
        expect(@import.cleaner_function).to be nil
        expect(@import.validation_function).to be nil
        expect(@import.preprocess_function).to be nil
      end

      it 'require valid functions for cleaner/validation/preprocess' do
        @import.cleaner_function = 'import_cleaner'
        @import.validation_function = 'import_validator'
        expect(@import).to be_valid

        @import.preprocess_function = 'missing_func'
        expect(@import).to_not be_valid
        expect(@import.errors[:base][0]).
          to eq 'unknown class method missing_func'
      end
    end
  end
end
