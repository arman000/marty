require 'spec_helper'

sample_script = <<DELOREAN
A:
    a =? 123.0
    b = a * 3

B: A
    c = a + b
    d =?
    e = c / a
    f = e * d

C:
    p0 =?
    a = 456.0 + p0

D:
    in =? "no input"
    out = in

DELOREAN

sample_script3 = <<eof
A:
    a = 2
    p =?
    c = a * 2
    pc = p + c
    lc = [pc, pc]

C: A
    p =? 3

B: A
    p =? 5
eof

sample_script4 = <<eof
import M3
A: M3::A
    p =? 10
    c = a * 2
    d = pc - 1
    e =?
    f =?
    g = e * 5 + f
    h = f + 1
    ptest = p * 10
    result = [{"a": 123, "b": 456}, {"a": 789, "b": 101112}]
eof

sample_script5 = <<eof
A:
    f =?
    res = if f == "Apple"
        then 0
        else if f == "Banana"
        then 1
        else if f == "Orange"
        then 2
        else 9
eof

sample_script6 = <<eof
A:
    b =?
    res = b + 1
eof

sample_script7 = <<eof
A:
    b =?
    res = b
eof

sample_script8 = <<eof
A:
    b =?
    res = 123
eof

script3_schema = <<eof
A:
    pc = { "properties : {
                  "p" : { "type" : "integer" },
                }
            }
eof

script4_schema = <<eof
A:
    d = { "properties" : {
            "p" : { "type" : "integer" },
                }
            }

    g = { "properties" : {
                  "e" : { "type" : "integer" },
                  "f" : { "type" : "integer" },
                }
          }

    lc = { "properties" : {
                  "p" : { "type" : "integer" },
                }
            }
eof

script5_schema = <<eof
A:
    res = { "properties" : {
            "f" : { "pg_enum" : "FruitsEnum" },
                }
            }
eof

script6_schema = <<eof
A:
    res = { "properties" : {
            "b" : { "type" : "float" },
                }
            }
eof

script7_schema = <<eof
A:
    res = { "properties" : {
            "b" : { "pg_enum" : "NonExistantEnum" },
                }
            }
eof

script8_schema = <<eof
A:
    res = { "properties" : {
            "b" : { "pg_enum" : "Gemini::MiDurationType" },
                }
            }
eof


describe Marty::RpcController do
  before(:each) {
    @routes = Marty::Engine.routes

    # HACKY: 'params' param is special to the Rails controller test helper (at
    # least as of 4.2). Setting this avoids test framework code that relies on
    # params being a hash.
    @request.env['PATH_INFO'] = "/marty/rpc/evaluate.json"
  }

  before(:each) {
    @p0 = Marty::Posting.do_create("BASE", Date.today, 'a comment')

    @t1 = Marty::Script.load_script_bodies({
                         "M1" => sample_script,
                         "M2" => sample_script.gsub(/a/, "aa").gsub(/b/, "bb"),
                         "M3" => sample_script3,
                         "M4" => sample_script4,
                         "M5" => sample_script5,
                         "M6" => sample_script6,
                         "M7" => sample_script7,
                         "M8" => sample_script8,
                         "M3Schemas" => script3_schema,
                         "M4Schemas" => script4_schema,
                         "M5Schemas" => script5_schema,
                         "M6Schemas" => script6_schema,
                         "M7Schemas" => script7_schema,
                         "M8Schemas" => script8_schema,
                       }, Date.today + 1.minute)

    @p1 = Marty::Posting.do_create("BASE", Date.today + 2.minute, 'a comment')

    @t2 = Marty::Script.load_script_bodies({
                         "M1" =>
                         sample_script.gsub(/A/, "AA")+'    e =? "hello"',
                       }, Date.today + 3.minute)

    @p2 = Marty::Posting.do_create("BASE", Date.today + 4.minute, 'a comment')
    @data = [["some data",7,[1,2,3],{foo: "bar", baz: "quz"},5,"string"],
             ["some more data",[1,2,3],5,{foo: "bar", baz: "quz"},5,"string"]]
    @data_json = [@data].to_json
  }

  let(:t1) { @t1 }
  let(:t2) { @t2 }
  let(:p0) { @p0 }
  let(:p1) { @p1 }
  let(:p2) { @p2 }

  it "should be able to post" do
    post 'evaluate', {
           format: :json,
           script: "M1",
           node: "B",
           attrs: ["e","f"].to_json,
           tag: t1.name,
           params: { a: 333, d: 5}.to_json,
         }
    expect(response.body).to eq([4,20].to_json)
  end

  it "should be able to post background job" do
    Delayed::Worker.delay_jobs = false
    post 'evaluate', {
           format: :json,
           script: "M1",
           node: "B",
           attrs: ["e","f"].to_json,
           tag: t1.name,
           params: { a: 333, d: 5}.to_json,
           background: true,
         }
    res = ActiveSupport::JSON.decode response.body
    expect(res).to include('job_id')
    job_id = res['job_id']

    promise = Marty::Promise.find_by_id(job_id)

    expect(promise.result).to eq({"e"=>4, "f"=>20})

    Delayed::Worker.delay_jobs = true
  end

  it "should be able to post background job with non-array attrs" do
    Delayed::Worker.delay_jobs = false
    post 'evaluate', {
           format: :json,
           script: "M1",
           node: "B",
           attrs: "e",
           tag: t1.name,
           params: { a: 333, d: 5}.to_json,
           background: true,
         }
    res = ActiveSupport::JSON.decode response.body
    expect(res).to include('job_id')
    job_id = res['job_id']

    promise = Marty::Promise.find_by_id(job_id)

    expect(promise.result).to eq({"e"=>4})

    Delayed::Worker.delay_jobs = true
  end

  it "should be able to post with complex data" do
    post 'evaluate', {
           format: :json,
           script: "M1",
           node: "D",
           attrs: ["out"].to_json,
           tag: t1.name,
           params: {in: @data}.to_json
         }
    expect(response.body).to eq(@data_json)
  end
  # content-type: application/json structures the request a little differently
  # so we also test that
  it "should be able to post (JSON) with complex data" do
    @request.env['CONTENT_TYPE'] = 'application/json'
    @request.env['ACCEPT'] = 'application/json'
    post 'evaluate', {
           format: :json,
           script: "M1",
           node: "D",
           attrs: ["out"].to_json,
           tag: t1.name,
           params: {in: @data}.to_json
         }
    expect(response.body).to eq(@data_json)
  end
  it "should be able to run scripts" do
    get 'evaluate', {
      format: :json,
      script: "M1",
      node: "A",
      attrs: ["a", "b"].to_json,
      tag: t1.name,
    }
    # puts 'Z'*40, request.inspect
    expect(response.body).to eq([123.0, 369.0].to_json)

    get 'evaluate', {
      format: :json,
      script: "M1",
      node: "A",
      attrs: ["a", "b"].to_json,
      params: {"a" => 4.5}.to_json,
      tag: t1.name,
    }
    expect(response.body).to eq([4.5,13.5].to_json)

    get 'evaluate', {
      format: :json,
      script: "M1",
      node: "B",
      attrs: ["a", "b", "c"].to_json,
      params: {"a" => 4.5}.to_json,
      tag: t1.name,
    }
    expect(response.body).to eq([4.5, 13.5, 18.0].to_json)

    get 'evaluate', {
      format: :json,
      script: "M1",
      tag: "DEV",
      node: "AA",
      attrs: ["a", "b"].to_json,
      params: {"a" => 3.3}.to_json,
    }
    res = ActiveSupport::JSON.decode(response.body).flatten.map{|x| x.round(8)}
    expect(res).to eq([3.3, 9.9])
  end

  it "should be able to use posting name for tags" do
    get 'evaluate', {
      format: :json,
      script: "M1",
      node: "A",
      attrs: ["a", "b"].to_json,
      tag: p0.name,
    }
    expect(response.body["error"]).to_not be_nil

    get 'evaluate', {
      format: :json,
      script: "M1",
      node: "A",
      attrs: ["a", "b"].to_json,
      params: {"a" => 4.5}.to_json,
      tag: p1.name,
    }
    expect(response.body).to eq([4.5,13.5].to_json)

    get 'evaluate', {
      format: :json,
      script: "M1",
      node: "B",
      attrs: ["a", "b", "c"].to_json,
      params: {"a" => 4.5}.to_json,
      tag: p2.name,
    }
    expect(response.body).to eq([4.5, 13.5, 18.0].to_json)

    get 'evaluate', {
      format: :json,
      script: "M1",
      tag: "NOW",
      node: "AA",
      attrs: ["a", "b"].to_json,
      params: {"a" => 3.3}.to_json,
    }
    res = ActiveSupport::JSON.decode(response.body).flatten.map{|x| x.round(8)}
    expect(res).to eq([3.3, 9.9])
  end

  it "should be able to run scripts 2" do
    get 'evaluate', {
      format: :json,
      script: "M3",
      node: "C",
      attrs: ["pc"].to_json,
    }
    # puts 'Z'*40, request.inspect
    expect(response.body).to eq([7].to_json)

    get 'evaluate', {
      format: :json,
      script: "M3",
      node: "B",
      attrs: ["pc"].to_json,
    }
    # puts 'Z'*40, request.inspect
    expect(response.body).to eq([9].to_json)

    get 'evaluate', {
      format: :json,
      script: "M3",
      node: "A",
      attrs: ["pc"].to_json,
    }
    # puts 'Z'*40, request.inspect
    expect(response.body).to match(/"error":"undefined parameter p"/)
  end

  it "should be able to handle imports" do
    get 'evaluate', {
      format: :json,
      script: "M4",
      node: "A",
      attrs: ["a", "c", "d", "pc"].to_json,
    }
    # puts 'Z'*40, request.inspect
    expect(response.body).to eq([2,4,13,14].to_json)
  end

  it "should support CSV" do
    get 'evaluate', {
      format: :csv,
      script: "M4",
      node: "A",
      attrs: ["a", "c", "d", "pc", "lc"].to_json,
    }
    # puts 'Z'*40, request.inspect
    expect(response.body).to eq("2\r\n4\r\n13\r\n14\r\n14,14\r\n")
  end

  it "should support CSV (2)" do
    get 'evaluate', {
      format: :csv,
      script: "M4",
      node: "A",
      attrs: ["result"].to_json,
    }
    # puts 'Z'*40, request.inspect
    expect(response.body).to eq("a,b\r\n123,456\r\n789,101112\r\n")
  end

  it "returns an error message on missing schema script (csv)" do
    Marty::ApiConfig.create!(script: "M1",
                             node: "A",
                             attr: nil,
                             logged: false,
                             validated: true)
    attrs = ["b"].to_json
    params = {"a" => 5}.to_json
    get 'evaluate', {
      format: :csv,
      script: "M1",
      node: "A",
      attrs: attrs,
      params: params
    }
    expect = "Schema error for M1/A attrs=b: Schema not defined\r\n"
    expect(response.body).to eq("error,#{expect}")
  end

  it "returns an error message on missing schema script (json)" do
    Marty::ApiConfig.create!(script: "M1",
                             node: "A",
                             attr: nil,
                             logged: false,
                             validated: true)
    attrs = ["b"].to_json
    params = {"a" => 5}.to_json
    get 'evaluate', {
      format: :json,
      script: "M1",
      node: "A",
      attrs: attrs,
      params: params
    }
    expect = "Schema error for M1/A attrs=b: Schema not defined"
    res_hsh = JSON.parse(response.body)
    expect(res_hsh.keys.size).to eq(1)
    expect(res_hsh.keys[0]).to eq("error")
    expect(res_hsh.values[0]).to eq(expect)
  end

  it "returns an error message on missing attributes in schema script" do
    Marty::ApiConfig.create!(script: "M4",
                             node: "A",
                             attr: nil,
                             logged: false,
                             validated: true)
    attrs = ["h"].to_json
    params = {"f" => 5}.to_json
    get 'evaluate', {
      format: :csv,
      script: "M4",
      node: "A",
      attrs: attrs,
      params: params
    }
    expect = "Schema error for M4/A attrs=h: Problem with schema\r\n"
    expect(response.body).to eq("error,#{expect}")
  end

  it "returns an error message on invalid schema" do
    Marty::ApiConfig.create!(script: "M3",
                             node: "A",
                             attr: nil,
                             logged: false,
                             validated: true)
    attrs = ["pc"].to_json
    params = {"p" => 5}.to_json
    get 'evaluate', {
      format: :csv,
      script: "M3",
      node: "A",
      attrs: attrs,
      params: params
    }
    expect = "Schema error for M3/A attrs=pc: Problem with schema\r\n"
    expect(response.body).to eq("error,#{expect}")
  end

  it "returns a validation error when validating a single attribute" do
    Marty::ApiConfig.create!(script: "M4",
                             node: "A",
                             attr: nil,
                             logged: false,
                             validated: true)
    attrs = ["d"].to_json
    params = {"p" => "132"}.to_json
    get 'evaluate', {
      format: :csv,
      script: "M4",
      node: "A",
      attrs: attrs,
      params: params
    }
    expect = '""d""=>[""The property \'#/p\' of type string did not '\
             'match the following type: integer'
    expect(response.body).to include(expect)
  end

  it "returns a validation error when validating multiple attributes" do
    Marty::ApiConfig.create!(script: "M4",
                             node: "A",
                             attr: nil,
                             logged: false,
                             validated: true)
    attrs = ["d", "g"].to_json
    params = {"p" => "132", "e" => "55", "f"=>"16"}.to_json
    get 'evaluate', {
      format: :csv,
      script: "M4",
      node: "A",
      attrs: attrs,
      params: params
    }
    expect = '""d""=>[""The property \'#/p\' of type string did not '\
             'match the following type: integer'
    expect(response.body).to include(expect)
    expect = '""g""=>[""The property \'#/e\' of type string did not '\
             'match the following type: integer'
    expect(response.body).to include(expect)
    expect = 'The property \'#/f\' of type string did not '\
             'match the following type: integer'
    expect(response.body).to include(expect)
  end

  it "validates schema" do
    Marty::ApiConfig.create!(script: "M4",
                             node: "A",
                             attr: nil,
                             logged: false,
                             validated: true)
    attrs = ["lc"].to_json
    params = {"p" => 5}.to_json
    get 'evaluate', {
      format: :csv,
      script: "M4",
      node: "A",
      attrs: attrs,
      params: params
    }
    expect(response.body).to eq("9\r\n9\r\n")
  end

  it "catches JSON::Validator exceptions" do
    Marty::ApiConfig.create!(script: "M6",
                             node: "A",
                             attr: nil,
                             logged: false,
                             validated: true)
    attrs = ["res"].to_json
    params = {"b" => 5.22}.to_json
    get 'evaluate', {
      format: :json,
      script: "M6",
      node: "A",
      attrs: attrs,
      params: params
    }
    expect = 'The property \'#/properties/b/type\' of type string '\
             'did not match one or more of the required schemas'
    res_hsh = JSON.parse(response.body)
    expect(res_hsh.keys.size).to eq(1)
    expect(res_hsh.keys[0]).to eq("error")
    expect(res_hsh.values[0]).to eq(expect)
  end


  class FruitsEnum
    VALUES=Set['Apple', 'Banana', 'Orange']
  end

  it "validates schema with a pg_enum (Positive)" do
    Marty::ApiConfig.create!(script: "M5",
                             node: "A",
                             attr: nil,
                             logged: false,
                             validated: true)
    attrs = ["res"].to_json
    params = {"f" => "Banana"}.to_json
    get 'evaluate', {
      format: :csv,
      script: "M5",
      node: "A",
      attrs: attrs,
      params: params
    }
    expect(response.body).to eq("1\r\n")
  end

  it "validates schema with a pg_enum (Negative)" do
    Marty::ApiConfig.create!(script: "M5",
                             node: "A",
                             attr: nil,
                             logged: false,
                             validated: true)
    attrs = ["res"].to_json
    params = {"f" => "Beans"}.to_json
    get 'evaluate', {
      format: :csv,
      script: "M5",
      node: "A",
      attrs: attrs,
      params: params
    }
    expect = '""res""=>[""Class error: \'Beans\' not contained in FruitsEnum'
    expect(response.body).to include(expect)
  end

  it "validates schema with a non-existant enum" do
    Marty::ApiConfig.create!(script: "M7",
                             node: "A",
                             attr: nil,
                             logged: false,
                             validated: true)
    attrs = ["res"].to_json
    params = {"b" => "MemberOfANonExistantEnum"}.to_json
    get 'evaluate', {
      format: :json,
      script: "M7",
      node: "A",
      attrs: attrs,
      params: params
    }
    expect = "Unrecognized PgEnum for attribute res"
    res_hsh = JSON.parse(response.body)
    expect(res_hsh.keys.size).to eq(1)
    expect(res_hsh.keys[0]).to eq("error")
    expect(res_hsh.values[0]).to include(expect)
  end

  it "validates pgenum with capitalization issues" do
    Marty::ApiConfig.create!(script: "M8",
                             node: "A",
                             attr: nil,
                             logged: false,
                             validated: true)
    skip "pending until a solution is found that handles "\
         "autoload issues involving constantize"
    attrs = ["res"].to_json
    params = {"b" => "Annual"}.to_json
    get 'evaluate', {
      format: :json,
      script: "M8",
      node: "A",
      attrs: attrs,
      params: params
    }
  end

  it "should log good req" do
    Marty::ApiConfig.create!(script: "M3",
                             node: "A",
                             attr: nil,
                             logged: true)
    attrs = ["lc"].to_json
    params = {"p" => 5}
    get 'evaluate', {
      format: :csv,
      script: "M3",
      node: "A",
      attrs: attrs,
      params: params.to_json
    }
    expect(response.body).to eq("9\r\n9\r\n")
    log = Marty::ApiLog.order(id: :desc).first

    expect(log.script).to eq("M3")
    expect(log.node).to eq("A")
    expect(log.attrs).to eq(attrs)
    expect(log.input).to eq(params)
    expect(log.output).to eq([[9, 9]])
    expect(log.remote_ip).to eq("0.0.0.0")
    expect(log.error).to eq(nil)

  end

  it "should log good req [background]" do
    Marty::ApiConfig.create!(script: "M3",
                             node: "A",
                             attr: nil,
                             logged: true)
    attrs = ["lc"].to_json
    params = {"p" => 5}
    get 'evaluate', {
      format: :csv,
      script: "M3",
      node: "A",
      attrs: attrs,
      params: params.to_json,
      background: true
    }
    expect(response.body).to match(/job_id,/)
    log = Marty::ApiLog.order(id: :desc).first

    expect(log.script).to eq("M3")
    expect(log.node).to eq("A")
    expect(log.attrs).to eq(attrs)
    expect(log.input).to eq(params)
    expect(log.output).to include("job_id")
    expect(log.remote_ip).to eq("0.0.0.0")
    expect(log.error).to eq(nil)

  end

  it "should not log if it should not log" do
    get 'evaluate', {
      format: :json,
      script: "M1",
      node: "A",
      attrs: ["a", "b"].to_json,
      tag: t1.name,
    }
    expect(Marty::ApiLog.count).to eq(0)
  end

  it "should handle atom attribute" do
    Marty::ApiConfig.create!(script: "M3",
                             node: "A",
                             attr: nil,
                             logged: true)
    params = {"p" => 5}
    get 'evaluate', {
      format: :csv,
      script: "M3",
      node: "A",
      attrs: "lc",
      params: params.to_json
    }
    expect(response.body).to eq("9\r\n9\r\n")
    log = Marty::ApiLog.order(id: :desc).first
    expect(log.script).to eq("M3")
    expect(log.node).to eq("A")
    expect(log.attrs).to eq("lc")
    expect(log.input).to eq(params)
    expect(log.output).to eq([9, 9])
    expect(log.remote_ip).to eq("0.0.0.0")
    expect(log.error).to eq(nil)
  end

  it "should support api authorization - api_key not required" do
    api = Marty::ApiAuth.new
    api.app_name = 'TestApp'
    api.script_name = 'M2'
    api.save!

    get 'evaluate', {
      format: :json,
      script: "M3",
      node: "C",
      attrs: ["pc"].to_json,
    }
    expect(response.body).to eq([7].to_json)
  end

  it "should support api authorization - api_key required but missing" do
    api = Marty::ApiAuth.new
    api.app_name = 'TestApp'
    api.script_name = 'M3'
    api.save!

    get 'evaluate', {
      format: :json,
      script: "M3",
      node: "C",
      attrs: ["pc"].to_json,
    }
    expect(response.body).to match(/"error":"Permission denied"/)
  end

  it "should support api authorization - api_key required and supplied" do
    api = Marty::ApiAuth.new
    api.app_name = 'TestApp'
    api.script_name = 'M3'
    api.save!

    apic = Marty::ApiConfig.create!(script: 'M3',
                                    logged: true)

    get 'evaluate', {
      format: :json,
      script: "M3",
      node: "C",
      attrs: ["pc"].to_json,
      api_key: api.api_key,
    }
    expect(response.body).to eq([7].to_json)
    log = Marty::ApiLog.order(id: :desc).first
    expect(log.script).to eq('M3')
    expect(log.node).to eq('C')
    expect(log.attrs).to eq(%Q!["pc"]!)
    expect(log.output).to eq([7])
    expect(log.remote_ip).to eq("0.0.0.0")
    expect(log.auth_name).to eq("TestApp")
  end

  it "should support api authorization - api_key required but incorrect" do
    api = Marty::ApiAuth.new
    api.app_name = 'TestApp'
    api.script_name = 'M3'
    api.save!

    get 'evaluate', {
      format: :json,
      script: "M3",
      node: "C",
      attrs: ["pc"].to_json,
      api_key: api.api_key + 'x',
    }
    expect(response.body).to match(/"error":"Permission denied"/)
  end

  context "error handling" do
    it 'returns bad attrs if attrs is not a string' do
      get :evaluate, format: :json, attrs: 0
      expect(response.body).to match(/"error":"Malformed attrs"/)
    end

    it 'returns malformed attrs for improperly formatted json' do
      get :evaluate, format: :json, attrs: "{"
      expect(response.body).to match(/"error":"Malformed attrs"/)
    end

    it 'returns malformed attrs if attrs is not an array of strings' do
      get :evaluate, format: :json, attrs: "{}"
      expect(response.body).to match(/"error":"Malformed attrs"/)

      get :evaluate, format: :json, attrs: "[0]"
      expect(response.body).to match(/"error":"Malformed attrs"/)
    end

    it 'returns bad params if params is not a string' do
      get(:evaluate, format: :json, params: 0)
      expect(response.body).to match(/"error":"Bad params"/)
    end

    it 'returns malformed params for improperly formatted json' do
      get :evaluate, format: :json, params: "{"
      expect(response.body).to match(/"error":"Malformed params"/)
    end

    it 'returns malformed params if params is not a hash' do
      get :evaluate, format: :json, params: "[0]"
      expect(response.body).to match(/"error":"Malformed params"/)
    end

    it 'returns engine/tag lookup error if script not found' do
      get :evaluate, format: :json, script: 'M1', tag: 'invalid'
      expect(response.body).to match(/"error":"Can't get engine:/)
      get :evaluate, format: :json, script: 'Invalid', tag: t1.name
      expect(response.body).to match(/"error":"Can't get engine:/)
    end

    it 'returns the script runtime error (no node specified)' do
      get :evaluate, format: :json, script: 'M1', tag: t1.name
      expect(response.body).to match(/"error":"bad node/)
    end
  end
end
