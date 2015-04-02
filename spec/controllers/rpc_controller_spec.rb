require 'spec_helper'

sample_script = <<DELOREAN
A:
    a =? 123.0
    b = a * 3

B: A
    c = a + b
    d =?
    e = c / a

C:
    p0 =?
    a = 456.0 + p0
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
    result = [{"a": 123, "b": 456}, {"a": 789, "b": 101112}]
eof

describe Marty::RpcController do
  before(:each) do
    Mcfly.whodunnit = create_gemini_user
  end

  before(:each) { @routes = Marty::Engine.routes }

  before(:each) {
    # FIXME: this pre-seeding of the database should probably be handled differently
    Marty::PostingType.clear_lookup_cache!
    Marty::PostingType.seed

    create_now_posting
    create_dev_tag

    @p0 = Marty::Posting.do_create("BASE", Date.today, 'a comment')

    @t1 = load_script_bodies({
                         "M1" => sample_script,
                         "M2" => sample_script.gsub(/a/, "aa").gsub(/b/, "bb"),
                         "M3" => sample_script3,
                         "M4" => sample_script4,
                       }, Date.today + 1.minute)

    @p1 = Marty::Posting.do_create("BASE", Date.today + 2.minute, 'a comment')

    @t2 = load_script_bodies({
                         "M1" =>
                         sample_script.gsub(/A/, "AA")+'    e =? "hello"',
                       }, Date.today + 3.minute)

    @p2 = Marty::Posting.do_create("BASE", Date.today + 4.minute, 'a comment')
  }

  # FIXME: Should use a different method to pre-seed the database
  def create_dev_tag
    unless Marty::Tag.find_by_name('DEV')
      tag            = Marty::Tag.new
      tag.comment    = '---'
      tag.created_dt = 'infinity'
      tag.save!
    end
  end

  let(:t1) { @t1 }
  let(:t2) { @t2 }
  let(:p0) { @p0 }
  let(:p1) { @p1 }
  let(:p2) { @p2 }

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
    response.body.should == [4.5, 13.5, 18.0].to_json

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

    get 'evaluate', {
      format: :json,
      script: "M3",
      node: "C",
      attrs: ["pc"].to_json,
      api_key: api.api_key,
    }
    expect(response.body).to eq([7].to_json)
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
end
