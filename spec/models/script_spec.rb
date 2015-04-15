require 'spec_helper'

s1 =<<eof
NodeA:
  attr = 123
eof

s2 =<<eof
NodeB:
  attr = 456
eof

describe Marty::Script do
  describe '.load_a_script' do
    let(:now) { Time.zone.now - 1.minute }

    it "creates a new script if it doesn't already exist" do
      expect { Marty::Script.load_a_script('TestNew', s1, now) }.
        to change(Marty::Script, :count).by(1)
      expect(Marty::Script.lookup('infinity', 'TestNew').created_dt.to_s).
        to eq(now.to_s)
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
      expect { Marty::Script.load_a_script('TestExistsAndDifferent2',
                                           s2, now) }.
        to change { Marty::Script.where(name: 'TestExistsAndDifferent2',
                                        obsoleted_dt: 'infinity').count }.by(0)
      expect(Marty::Script.lookup('infinity', 'TestExistsAndDifferent2').
             created_dt.to_s).to eq(now.to_s)
    end
  end

  describe '.load_script_bodies' do
    before(:each) do
      allow(Marty::Script).to receive(:load_a_script)
    end

    let(:now) { Time.zone.now - 1.minute }

    it 'loads each script' do
      Marty::Script.load_script_bodies({'Test1' => s1, 'Test2' => s2}, now)
      expect(Marty::Script).to have_received(:load_a_script).twice
    end

    it 'creates a new tag if none exist yet with provided datetime' do
      expect { @tag = Marty::Script.load_script_bodies({'Test1' => s1,
                                                        'Test2' => s2}, now) }.
        to change(Marty::Tag, :count).by(1)
      expect(@tag.created_dt).to eq(now + 1.second)
    end

    it 'creates a new tag when there is an older one present' do
      Marty::Tag.do_create(now - 1.minute, 'initial test tag')
      expect { @tag = Marty::Script.load_script_bodies({'Test1' => s1,
                                                        'Test2' => s2}, now) }.
        to change(Marty::Tag, :count).by(1)
      expect(@tag.created_dt).to eq(now + 1.second)
    end

    it 'creates a new tag when no previous tag is present and no datetime ' +
      'provided' do
      expect { tag = Marty::Script.load_script_bodies({'Test1' => s1,
                                                       'Test2' => s2}) }.
        to change(Marty::Tag, :count).by(1)
    end

    it "doesn't create a new tag if one is present and the script wasn't" +
      "modified" do
      Marty::Script.create!(name: 'Test1', body: s1, created_dt: now)
      Marty::Tag.do_create(now + 1.second, 'tag created by test')
      expect { Marty::Script.load_script_bodies({'Test1' => s1}) }.
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

    # FIXME: path defaults to "#{Rails.root}/db/gemini". Should probably
    # be something more Marty-appropriate

    it 'reads in the files and loads the script bodies' do
      Marty::Script.load_scripts(scripts_path, now)
      expect(Marty::Script).to have_received(:load_script_bodies).
        with({'Script1' => ls1, 'Script2' => ls2}, now)
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
