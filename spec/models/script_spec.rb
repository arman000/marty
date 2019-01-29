require 'spec_helper'

s1 = <<eof
NodeA:
  attr = 123
eof

s2 = <<eof
NodeB:
  attr = 456
eof

describe Marty::Script do
  describe '.load_a_script' do
    let(:now) { Time.zone.now - 1.minute }

    it "creates a new script if it doesn't already exist" do
      expect { Marty::Script.load_a_script('TestNew', s1, now) }.
        to change(Marty::Script, :count).by(1)
      expect(Marty::Script.find_by(obsoleted_dt: 'infinity', name: 'TestNew').
               created_dt.to_s).to eq(now.to_s)
    end

    it "doesn't create a new script entry if it already exists and is the " +
      "same as the existing" do
      Marty::Script.load_a_script('TestExistsAndSame', s1)
      expect { Marty::Script.load_a_script('TestExistsAndSame', s1) }.
        not_to change(Marty::Script, :count)
    end

    it 'updates the existing script entry if it already exists but is ' +
      'different' do
      Marty::Script.load_a_script('TestExistsAndDifferent1', s1)
      expect { Marty::Script.load_a_script('TestExistsAndDifferent1', s2) }.
        to change(Marty::Script, :count).by(1)

      Marty::Script.load_a_script('TestExistsAndDifferent2', s1, now - 1.minute)
      expect do
        Marty::Script.load_a_script('TestExistsAndDifferent2',
                                           s2, now)
      end      .
        to change {
             Marty::Script.where(name: 'TestExistsAndDifferent2',
                                        obsoleted_dt: 'infinity').count
           }           .by(0)
      expect(Marty::Script.find_by(
               obsoleted_dt: 'infinity', name: 'TestExistsAndDifferent2').
               created_dt.to_s).to eq(now.to_s)
    end
  end

  describe '.load_script_bodies' do
    before(:each) do
      allow(Marty::Script).to receive(:load_a_script)
    end

    let(:now) { Time.zone.now - 1.minute }

    it 'loads each script given a hash' do
      Marty::Script.load_script_bodies({ 'Test1' => s1, 'Test2' => s2 }, now)
      expect(Marty::Script).to have_received(:load_a_script).
        with('Test1', s1, now)
      expect(Marty::Script).to have_received(:load_a_script).
        with('Test2', s2, now)
      expect(Marty::Script).to have_received(:load_a_script).twice
    end

    it 'loads each script given an array of tuples' do
      Marty::Script.load_script_bodies([['Test1', s1], ['Test2', s2]], now)
      expect(Marty::Script).to have_received(:load_a_script).
        with('Test1', s1, now)
      expect(Marty::Script).to have_received(:load_a_script).
        with('Test2', s2, now)
      expect(Marty::Script).to have_received(:load_a_script).twice
    end

    it 'creates a new tag if none exist yet with provided datetime' do
      expect do
        @tag = Marty::Script.load_script_bodies({ 'Test1' => s1,
                                                        'Test2' => s2 }, now)
      end      .
        to change(Marty::Tag, :count).by(1)
      expect(@tag.created_dt).to eq(now + 1.second)
    end

    it 'creates a new tag when there is an older one present' do
      Marty::Tag.do_create(now - 1.minute, 'initial test tag')
      expect do
        @tag = Marty::Script.load_script_bodies({ 'Test1' => s1,
                                                        'Test2' => s2 }, now)
      end      .
        to change(Marty::Tag, :count).by(1)
      expect(@tag.created_dt).to eq(now + 1.second)
    end

    it 'creates a new tag when no previous tag is present and no datetime ' +
      'provided' do
      expect do
        tag = Marty::Script.load_script_bodies({ 'Test1' => s1,
                                                       'Test2' => s2 })
      end      .
        to change(Marty::Tag, :count).by(1)
    end

    it "doesn't create a new tag if one is present and the script wasn't" +
      "modified" do
      Marty::Script.create!(name: 'Test1', body: s1, created_dt: now)
      Marty::Tag.do_create(now + 1.second, 'tag created by test')
      expect { Marty::Script.load_script_bodies({ 'Test1' => s1 }) }.
        not_to change(Marty::Tag, :count)
    end
  end

  describe '.load_scripts' do
    before(:each) do
      allow(Marty::Script).to receive(:load_script_bodies)
    end

    let(:scripts_path) do
      File.expand_path('../../fixtures/scripts/load_tests', __FILE__)
    end
    let(:now) { Time.zone.now - 1.minute }
    let(:ls1) { File.read("#{scripts_path}/script1.dl") }
    let(:ls2) { File.read("#{scripts_path}/script2.dl") }

    it 'reads in the files and loads the script bodies' do
      Marty::Script.load_scripts(scripts_path, now)
      expect(Marty::Script).to have_received(:load_script_bodies).
        with(match_array([['Script1', ls1], ['Script2', ls2]]), now)
    end
  end

  describe '.get_script_filenames' do
    context 'with single directory passed in' do
      before(:each) do
        allow(Dir).to receive(:glob).and_return(script_files)
      end

      let(:script_files) { ['/test/script1.dl', '/test/script2.dl'] }

      it 'gets the files from the specified directory' do
        Marty::Script.get_script_filenames('/test')
        expect(Dir).to have_received(:glob).with('/test/*.dl')
      end

      it 'returns the files in the given directory' do
        expect(Marty::Script.get_script_filenames('/test')).
          to match_array(script_files)
      end
    end

    context 'with duplicate script file names' do
      it 'returns only the unique file names' do
        allow(Dir).to receive(:glob).with('/test1/*.dl').
          and_return(['/test1/sc1.dl', '/test1/sc2.dl'])
        allow(Dir).to receive(:glob).with('/test2/*.dl').
          and_return(['/test2/sc2.dl', '/test2/sc3.dl'])
        expect(Marty::Script.get_script_filenames(['/test1', '/test2'])).
          to match_array(['/test1/sc1.dl', '/test1/sc2.dl', '/test2/sc3.dl'])
      end
    end

    context 'using default directories' do
      it 'gets the files from the default paths' do
        allow(Dir).to receive(:glob).and_return([])
        Marty::Script.get_script_filenames
        expect(Dir).to have_received(:glob).with("#{Rails.root}/delorean/*.dl")
        expect(Dir).to have_received(:glob).
          with(File.expand_path('../../../delorean/*.dl', __FILE__))
        expect(Dir).to have_received(:glob).twice
      end
    end

    context 'with Rails.configuration.marty.delorean_scripts_path' do
      before(:each) do
        Rails.configuration.marty.delorean_scripts_path = ['/conf_test']
      end
      after(:each) { Rails.configuration.marty.delorean_scripts_path = nil }

      it 'gets the files from the specified path' do
        allow(Dir).to receive(:glob).and_return([])
        Marty::Script.get_script_filenames
        expect(Dir).to have_received(:glob).with('/conf_test/*.dl')
      end
    end
  end

  describe '.delete_scripts' do
    it 'removes all the scripts' do
      Marty::Script.create!(name: 'TestScript1', body: s1)
      Marty::Script.create!(name: 'TestScript2', body: s2)

      Marty::Script.delete_scripts
      expect(Marty::Script.count).to eq(0)
    end
  end
end
