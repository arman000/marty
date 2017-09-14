require 'spec_helper'

module Marty
  describe Marty::Config do
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

      def testval_fail(val)
        expect{testval(val)}.to raise_error(ActiveRecord::RecordInvalid,
                                            'Validation failed: bad JSON value')
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

      it "should handle del" do
        (0..10).each { |i|
          v = {"i" => i}
          Marty::Config["k#{i}"] = v
          expect(Marty::Config["k#{i}"]).to eq(v)
        }

        (0..10).each { |i|
          Marty::Config.del("k#{i}")
          expect(Marty::Config["k#{i}"]).to eq(nil)
        }
      end

      it "should allow the assignment of individual boolean values" do
        testval(true)
        testval(false)
      end

      it "should not allow the assignment of individual nil (null) values" do
        testval_fail(nil)
      end

      it "should allow nil (null) to exist in other structures" do
        testval([nil, 1, 2, nil])
        testval({"key1"  => nil, "key2" => false, "key3" => 'val'})
      end
    end
  end
end
