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
    i =?
    ptest = p * 10
    ii = i
    result = [{"a": p, "b": 456}, {"a": 789, "b": p}]
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
    result =  [{"a": "str", "b": 456}, {"a": 789, "b": "str"}]
    result2 = [{"a": "str", "b": 456}, {"a": 789, "b": "str"}]
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

sample_script9 = <<eof
A:
    b =?
    res = b + 1
    result = [{"a": 1, "b": res}, {"a": 789, "b": res}]
eof

sample_script10 = <<eof
A:
    opt1 =?
    optn =?
    opttf =?
    opttrue =?
    optfalse =?
    req1 =?
    req2 =?
    req3 =?

    optif = if opttf == true
               then opttrue
               else if opttf == false
                    then optfalse
                    else nil

    v1 = if req1 == 'no opts'
            then req2
            else if req1 == "opt1"
                    then opt1
                    else if req2 != 'no opts'
                            then optn
                            else if req3 == "opttf"
                                   then optif
                                   else 'req3'

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
    d_ = { "type" : "integer" }

    ii = {}

    ii_ = { "type" : "integer" }

    g = { "properties" : {
                  "e" : { "type" : "integer" },
                  "f" : { "type" : "integer" },
                }
          }

    g_ = { "type" : "integer" }

    lc = { "properties" : {
                  "p" : { "type" : "integer" },
                }
            }

    result = { "properties" : {
            "p" : { "type" : "integer" },
                }
             }

    result_ = {
                 "type": "array",
                 "minItems": 1,
                 "items": {
                   "type": "object",
                   "properties": {
                       "a": { "type" : "integer" },
                       "b": { "type" : "integer" }
                }
              }
          }
eof

script5_schema = <<eof
A:
    res = { "properties" : {
            "f" : { "pg_enum" : "FruitsEnum" },
                }
            }

    result = { "properties" : {
            "f" : { "pg_enum" : "FruitsEnum" },
                }
            }

    result_ = { "type": "array",
                 "minItems": 1,
                 "items": {
                   "type": "object",
                   "properties": {
                       "a": { "type" : "integer" },
                       "b": { "type" : "string" }
                   }
                }
             }

    result2 = { "properties" : {
            "f" : { "pg_enum" : "FruitsEnum" },
                }
            }

    result2_ = { "type": "array",
                 "minItems": 1,
                 "items": {
                   "type": "object",
                   "properties": {
                       "a": { "type" : "integer" },
                       "b": { "type" : "string" }
                   }
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

script9_schema = <<eof
A:
    res = { "properties" : {
            "b" : { "type" : "number" },
                }
            }

    result = { "properties" : {
            "b" : { "type" : "number" },
                }
            }

    result_ = {  "type": "array",
                 "minItems": 1,
                 "items": {
                   "type": "object",
                   "properties": {
                       "a": { "type" : "integer" },
                       "b": { "type" : "integer" },
                       "c": { "type" : "string" }
                   },
                   "required" : ["a", "b", "c"]
                }
          }
eof

script10_schema = <<eof
A:
    properties = {
              "opt1" :        { "type" : "string" },
              "opttf" :       { "type" : "boolean" },
              "opttrue" :     { "type" : "string" },
              "optfalse" :    { "type" : "string" },
              "optdisallow" : { "type" : "string" },
              "req1" :        { "pg_enum" : "CondEnum" },
              "req2" :        { "pg_enum" : "CondEnum" }
         }

    req1_is_opt1 = Marty::SchemaHelper.enum_is('req1', ['opt1'])
    req2_is_not_no_opts = Marty::SchemaHelper.not(
                            Marty::SchemaHelper.enum_is('req2', ['no opts']))
    req3_is_opttf = Marty::SchemaHelper.enum_is('req3', ['opttf'])
    opttf_is_true = Marty::SchemaHelper.bool_is('opttf', true)
    opttf_is_false = Marty::SchemaHelper.bool_is('opttf', false)

    # opt1 is required if req1 == 'opt1'
    opt1_check = Marty::SchemaHelper.required_if(['opt1'], req1_is_opt1)

    # optn is required if req2 != 'no opts'
    optn_check = Marty::SchemaHelper.required_if(['optn'], req2_is_not_no_opts)

    # opttf is required if req3 == 'opttf'
    opttf_check = Marty::SchemaHelper.required_if(['opttf'], req3_is_opttf)

    # opttrue is required if opttf is true
    opttrue_check = Marty::SchemaHelper.required_if(['opttrue'], opttf_is_true)

    # optfalse is required if opttf is false
    optfalse_check = Marty::SchemaHelper.required_if(['optfalse'],
                                                     opttf_is_false)

    # optdisallow is not allowed if opttf is false
    optdisallow_check = Marty::SchemaHelper.disallow_if_conds(['optdisallow'],
                                                        opttf_is_false)

    # opttf is optional (contingent on req3) so eval of opttrue_check
    # and optfalse_check is dependent upon opttf existing
    opttruefalse_check = Marty::SchemaHelper.dep_check('opttf',
                                                    opttrue_check,
                                                    optfalse_check,
                                                    optdisallow_check)

    dip_check = Marty::SchemaHelper.disallow_if_present('opttf',
                                                        'opt3', 'opt4')

    dinp_check = Marty::SchemaHelper.disallow_if_not_present('opttf',
                                                        'opt5', 'opt6')

    v1 = { "properties": properties,
           "required": ["req1", "req2", "req3"],
           "allOf": [
                     opt1_check,
                     optn_check,
                     opttf_check,
                     opttruefalse_check,
                     dip_check,
                     dinp_check
             ] }
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
                         "M9" => sample_script9,
                         "M10" => sample_script10,
                         "M3Schemas" => script3_schema,
                         "M4Schemas" => script4_schema,
                         "M5Schemas" => script5_schema,
                         "M6Schemas" => script6_schema,
                         "M7Schemas" => script7_schema,
                         "M8Schemas" => script8_schema,
                         "M9Schemas" => script9_schema,
                         "M10Schemas" => script10_schema,
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

  after(:each) do
    Marty::Log.delete_all
  end

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
    expect(response.body).to eq("a,b\r\n10,456\r\n789,10\r\n")
  end

  it "returns an error message on missing schema script (csv)" do
    Marty::ApiConfig.create!(script: "M1",
                             node: "A",
                             attr: nil,
                             logged: false,
                             input_validated: true)
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
                             input_validated: true)
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
                             input_validated: true)
    attrs = ["h"].to_json
    params = {"f" => 5}.to_json
    get 'evaluate', {
      format: :csv,
      script: "M4",
      node: "A",
      attrs: attrs,
      params: params
    }
    expect = "Schema error for M4/A attrs=h: Problem with schema"
    expect(response.body).to include("error,#{expect}")
  end

  it "returns an error message on invalid schema" do
    Marty::ApiConfig.create!(script: "M3",
                             node: "A",
                             attr: nil,
                             logged: false,
                             input_validated: true)
    attrs = ["pc"].to_json
    params = {"p" => 5}.to_json
    get 'evaluate', {
      format: :csv,
      script: "M3",
      node: "A",
      attrs: attrs,
      params: params
    }
    expect = "Schema error for M3/A attrs=pc: Problem with schema: "\
             "syntax error M3Schemas:2\r\n"
    expect(response.body).to eq("error,#{expect}")
  end

  it "returns a validation error when validating a single attribute" do
    Marty::ApiConfig.create!(script: "M4",
                             node: "A",
                             attr: nil,
                             logged: false,
                             input_validated: true)
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
                             input_validated: true,
                             output_validated: true)
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

  context "output_validation" do
    it "validates output" do
      Marty::ApiConfig.create!(script: "M4",
                               node: "A",
                               attr: nil,
                               logged: false,
                               input_validated: true,
                               output_validated: true,
                               strict_validate: true)
      attrs = ["d", "g", "ii", "result"].to_json
      params = {"p" => 132, "e" => 55, "f"=>16, "i"=>"string"}.to_json
      get 'evaluate', {
            format: :json,
            script: "M4",
            node: "A",
            attrs: attrs,
            params: params
          }
      res_hash = JSON.parse(response.body)
      errpart = "of type string did not match the following type: integer"
      expect(res_hash[0]).to eq(135)
      expect(res_hash[1]).to eq(291)
      expect(res_hash[2]["error"]).to include(errpart)
      expect(res_hash[3]).to eq([{"a"=>132,"b"=>456},
                                 {"a"=>789,"b"=>132}])
      logs = Marty::Log.all
      expect(logs.count).to eq(1)
      expect(logs[0].details["error"][0]).to include(errpart)
    end
    it "validates output 2" do
      # not all attrs being validated
      Marty::ApiConfig.create!(script: "M4",
                               node: "A",
                               attr: "result",
                               logged: false,
                               input_validated: true,
                               output_validated: true)
      attrs = ["d", "g", "result"].to_json
      params = {"p" => 132, "e" => 55, "f"=>16}.to_json
      get 'evaluate', {
            format: :json,
            script: "M4",
            node: "A",
            attrs: attrs,
            params: params
          }
      res_hash = JSON.parse(response.body)
      expect(res_hash).to eq([135,291,[{"a"=>132,"b"=>456},
                                       {"a"=>789,"b"=>132}]])
      logs = Marty::Log.all
      expect(logs.count).to eq(0)
    end

    it "validates output (bad type, with strict/non strict errors)" do
      Marty::ApiConfig.create!(script: "M5",
                               node: "A",
                               attr: nil,
                               logged: false,
                               input_validated: true,
                               output_validated: true,
                               strict_validate: true)
      Marty::ApiConfig.create!(script: "M5",
                               node: "A",
                               attr: "result2",
                               logged: false,
                               input_validated: true,
                               output_validated: true,
                               strict_validate: false)
      attrs = ["result", "result2"].to_json
      params = {"f" => "Banana"}.to_json
      get 'evaluate', {
            format: :json,
            script: "M5",
            node: "A",
            attrs: attrs,
            params: params
          }
      res_hash = JSON.parse(response.body)
      expect(res_hash[0]).to include("error")
      expect1 = "The property '#/0/b' of type integer did not match the "\
               "following type: string"
      expect2 = "The property '#/0/a' of type string did not match the "\
                "following type: integer"
      expect(res_hash[0]["error"]).to include(expect1)
      expect(res_hash[0]["error"]).to include(expect2)

      logs = Marty::Log.all
      expect(logs.count).to eq(2)
      expect(logs[0].message).to eq("API M5:A.result")
      expect(logs[1].message).to eq("API M5:A.result2")
      logs.each do |ml|
        expect(ml.details["error"].join).to include(expect1)
        expect(ml.details["error"].join).to include(expect2)
        expect(ml.details["data"]).to eq([{"a"=>"str", "b"=>456},
                                          {"a"=>789, "b"=>"str"}])
      end
    end

    it "validates output (missing item)" do
      Marty::ApiConfig.create!(script: "M9",
                               node: "A",
                               attr: nil,
                               logged: false,
                               input_validated: true,
                               output_validated: true,
                               strict_validate: true)
      attrs = ["result"].to_json
      params = {"b" => 122}.to_json
      get 'evaluate', {
            format: :json,
            script: "M9",
            node: "A",
            attrs: attrs,
            params: params
          }
      res_hash = JSON.parse(response.body)
      expect(res_hash[0]).to include("error")
      expect1 = "The property '#/0' did not contain a required property of 'c'"
      expect2 = "The property '#/1' did not contain a required property of 'c'"
      expect(res_hash[0]["error"]).to include(expect1)
      expect(res_hash[0]["error"]).to include(expect2)

      logs = Marty::Log.all
      expect(logs.count).to eq(1)
      expect(logs[0].message).to eq("API M9:A.result")
      expect(logs[0].details["error"].join).to include(expect1)
      expect(logs[0].details["error"].join).to include(expect2)
      expect(logs[0].details["data"]).to eq([{"a"=>1, "b"=>123},
                                             {"a"=>789, "b"=>123}])
    end
  end

  it "validates schema" do
    Marty::ApiConfig.create!(script: "M4",
                             node: "A",
                             attr: nil,
                             logged: false,
                             input_validated: true)
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
                             input_validated: true)
    attrs = ["res"].to_json
    params = {"b" => 5.22}.to_json
    get 'evaluate', {
      format: :json,
      script: "M6",
      node: "A",
      attrs: attrs,
      params: params
    }
    expect = 'res: The property \'#/properties/b/type\' of type string '\
             'did not match one or more of the required schemas'
    res_hsh = JSON.parse(response.body)
    expect(res_hsh.keys.size).to eq(1)
    expect(res_hsh.keys[0]).to eq("error")
    expect(res_hsh.values[0]).to eq(expect)
  end


  class FruitsEnum
    VALUES=Set['Apple', 'Banana', 'Orange']
  end
  class CondEnum
    VALUES=Set['no opts','opt1','opt2','opttf']
  end

  it "validates schema with a pg_enum (Positive)" do
    Marty::ApiConfig.create!(script: "M5",
                             node: "A",
                             attr: nil,
                             logged: false,
                             input_validated: true)
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
                             input_validated: true)
    attrs = ["res"].to_json
    params = {"f" => "Beans"}.to_json
    get 'evaluate', {
      format: :csv,
      script: "M5",
      node: "A",
      attrs: attrs,
      params: params
    }
    expect = "property '#/f' value 'Beans' not contained in FruitsEnum"
    expect(response.body).to include(expect)
  end

  it "validates schema with a non-existant enum" do
    Marty::ApiConfig.create!(script: "M7",
                             node: "A",
                             attr: nil,
                             logged: false,
                             input_validated: true)
    attrs = ["res"].to_json
    params = {"b" => "MemberOfANonExistantEnum"}.to_json
    get 'evaluate', {
      format: :json,
      script: "M7",
      node: "A",
      attrs: attrs,
      params: params
    }
    expect = "property '#/b': 'NonExistantEnum' is not a pg_enum"
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
                             input_validated: true)
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
    attrs = ["lc"]
    params = {"p" => 5}
    get 'evaluate', {
      format: :csv,
      script: "M3",
      node: "A",
      attrs: attrs.to_json,
      params: params.to_json
    }
    expect(response.body).to eq("9\r\n9\r\n")
    log = Marty::Log.order(id: :desc).first

    expect(log.script).to eq("M3")
    expect(log.node).to eq("A")
    expect(log.attrs).to eq(attrs)
    expect(log.input).to eq(params)
    expect(log.output).to eq([[9,9]])
    expect(log.remote_ip).to eq("0.0.0.0")
    expect(log.error).to eq(nil)

  end

  it "should log good req [background]" do
    Marty::ApiConfig.create!(script: "M3",
                             node: "A",
                             attr: nil,
                             logged: true)
    attrs = ["lc"]
    params = {"p" => 5}
    get 'evaluate', {
      format: :csv,
      script: "M3",
      node: "A",
      attrs: attrs.to_json,
      params: params.to_json,
      background: true
    }
    expect(response.body).to match(/job_id,/)
    log = Marty::Log.order(id: :desc).first

  end

  it "should not log if it should not log" do
    get 'evaluate', {
      format: :json,
      script: "M1",
      node: "A",
      attrs: ["a", "b"].to_json,
      tag: t1.name,
    }
    expect(Marty::Log.count).to eq(0)
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
    log = Marty::Log.order(id: :desc).first

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

    attrs = ["pc"]
    get 'evaluate', {
      format: :json,
      script: "M3",
      node: "C",
      attrs: attrs.to_json,
      api_key: api.api_key,
    }
    expect(response.body).to eq([7].to_json)
    log = Marty::Log.order(id: :desc).first

    expect(log.script).to eq("M3")
    expect(log.node).to eq("C")
    expect(log.attrs).to eq(attrs)
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

  context "conditional validation" do
    before(:all) do
      Marty::ApiConfig.create!(script: "M10",
                               node: "A",
                               attr: nil,
                               logged: false,
                               input_validated: true,
                               output_validated: false,
                               strict_validate: false)
    end
    def do_call(req1, req2, req3, optionals={})
      attrs = ["v1"].to_json
      params = optionals.merge({"req1" => req1,
                                "req2"=> req2,
                                "req3"=> req3}).to_json

      # to see what the schema helpers generated:
      # engine = Marty::ScriptSet.new(nil).get_engine("M10Schemas")
      # x=engine.evaluate("A", ["v1"],  {})
      # binding.pry

      get 'evaluate', {
            format: :json,
            script: "M10",
            node: "A",
            attrs: attrs,
            params: params
          }

    end

    it "does conditional" do
      aggregate_failures "conditionals" do
        [
          # first group has all required fields
          [['opt1', 'no opts', 'no opts', opt1: 'hi mom'], "hi mom"],
          [['no opts', 'no opts', 'no opts', opt1: 'hi mom'], "no opts"],
          [['opt2', 'opt2', 'no opts', optn: 'foo'], 'foo'],
          [['opt2', 'no opts', 'opt2'], 'req3'],
          [['opt2', 'no opts', 'opttf', opttf: true, opttrue: 'bar'], 'bar'],
          [['opt2', 'no opts', 'opttf', opttf: false, optfalse: 'baz'], 'baz'],

          # second group is missing fields or has other errors
          [['opt1', 'no opts', 'no opts'],
           "did not contain a required property of 'opt1'"],
          [['opt2', 'opt2', 'no opts',],
           "did not contain a required property of 'optn'"],
          [['opt2', 'no opts', 'opttf'],
           "did not contain a required property of 'opttf'"],
          [['opt2', 'no opts', 'opttf', opttf: true],
           "did not contain a required property of 'opttrue'"],
          [['opt2', 'no opts', 'opttf', opttf: false],
           "did not contain a required property of 'optfalse'"],
          [['opt2', 'no opts', 'opttf', opttf: false, optfalse: "val",
            optdisallow: "hi mom"],
           "disallowed parameter 'optdisallow' of type string was received"],
          [['opt2', 'no opts', 'opttf', opttf: false, optfalse: "val",
            opt3: "hi"],
           "disallowed parameter 'opt3' of type string was received"],
          [['opt2', 'no opts', 'opttf', opttf: true, opttrue: "val",
            opt4: "mom"],
           "disallowed parameter 'opt4' of type string was received"],
          [['opt2', 'no opts', 'xyz', opt5: "hi"],
           "disallowed parameter 'opt5' of type string was received"],
        ].each do
          |a, exp|
          do_call(*a)
          res_hash = JSON.parse(response.body)
          got = res_hash.is_a?(Array) ? res_hash[0] : res_hash["error"]

          expect(got).to include(exp)
        end
      end
    end
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
