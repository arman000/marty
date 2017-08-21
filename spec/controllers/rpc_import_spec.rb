require 'spec_helper'

describe Marty::RpcController do
  before(:each) { @routes = Marty::Engine.routes }

  before(:each) {
    @tags = []
    @tags << Marty::Script.load_script_bodies({
                         "A" => "A:\n    a = 1\n",
                         "B" => "B:\n    b = 0\n",
                       }, Date.today)

    @tags << Marty::Script.load_script_bodies({
                         "B" => "import A\nB:\n    b = A::A().a\n",
                       }, Date.today + 1.minute)

    @tags << Marty::Script.load_script_bodies({
                         "A" => "A:\n    a = 2\n",
                       }, Date.today + 2.minute)


    # create an untagged version for DEV
    s = Marty::Script.lookup('infinity', "A")
    s.body = "A:\n    a = 3\n"
    s.save!
  }

  let(:tags) { @tags }

  it "should properly import different versions of a script" do
    # try the test 3 times for fun
    (0..2).each {
      tags.each_with_index { |t, i|
        get 'evaluate', params: {
          format: :json,
          script: "B",
          node: "B",
          attrs: ["b"].to_json,
          tag: t.name,
        }
        response.body.should == [i].to_json
      }
    }
  end
end
