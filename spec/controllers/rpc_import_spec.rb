describe Marty::RpcController do
  before(:each) { @routes = Marty::Engine.routes }

  before(:each) do
    @tags = []
    @tags << Marty::Script.load_script_bodies({
                         'A' => "A:\n    a = 1\n",
                         'B' => "B:\n    b = 0\n",
                        }, Time.zone.today)

    @tags << Marty::Script.load_script_bodies({
                         'B' => "import A\nB:\n    b = A::A().a\n",
                        }, Time.zone.today + 1.minute)

    @tags << Marty::Script.load_script_bodies({
                         'A' => "A:\n    a = 2\n",
                        }, Time.zone.today + 2.minutes)

    # create an untagged version for DEV
    s = Marty::Script.find_by(obsoleted_dt: 'infinity', name: 'A')
    s.body = "A:\n    a = 3\n"
    s.save!
  end

  let(:tags) { @tags }

  it 'should properly import different versions of a script' do
    # try the test 3 times for fun
    (0..2).each do
      tags.each_with_index do |t, i|
        get 'evaluate', params: {
              format: :json,
              script: 'B',
              node: 'B',
              attrs: 'b',
              tag: t.name,
            }
        response.body.should == i.to_json
      end
    end
  end
end
