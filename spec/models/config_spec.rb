require 'spec_helper'

module Marty
  describe Config do
    describe "validations" do
      it "should return valid config value based on key" do
        Marty::Config["TEST 1"] = 2
        expect(Marty::Config.lookup("TEST 1")).to eq(2)
        expect(Marty::Config["TEST 1"]).to eq(2)
      end

      def testval(val)
        Marty::Config["testval"] = val
        expect(Marty::Config.lookup("testval")).to eq(val)
        expect(Marty::Config["testval"]).to eq(val)
      end

      it "should handle various structures correctly" do
        testval("[1,2,3]")
        testval("[1,\"2,3\"]")
        testval([1,2,3])
        testval([1,"2,3"])

        testval({ "key1" => [1,2,3], "keystr" => { "val" => "val"}})
        testval(%Q({ "key1" : [1,2,3], "keystr" : { "val" : "val"}}))

        testval("123456.1234")
        testval("a string")
        testval("\"a string\"")
      end

      it "should return nil config value for non-existing key" do
        expect(Marty::Config.lookup("TEST 2")).to eq(nil)
        expect(Marty::Config["TEST 2"]).to eq(nil)
      end
    end
  end
end
