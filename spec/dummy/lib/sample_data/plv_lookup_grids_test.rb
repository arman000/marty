require 'benchmark'

#
# This test script should be run in with Gemini's rails console
# load "plv_lookup_grids_test.rb"
#

Rails.logger.level = 5
Dir.mkdir('test_res')  unless File.exists?('test_res')

#
# PLV8 specific functions
#
SAMPLE_LOAN = {
  "client_id"                             => 700092,
  "commitment_days"                       => 60,
  "property_state"                        => "VA",
  "automated_underwriting_system_type"    => "DesktopUnderwriter",
  "mortgage_type"                         => "VA",
  "amortization_type"                     => "Fixed",
  "loan_amortization_period_count"        => 360,
  "note_rate"                             => 4.25,
  "base_loan_amount"                      => 323899.3,
  "note_amount"                           => 334588.0,
  "ltv_ratio_percent"                     => 103.30,
  "cltv_ratio_percent"                    => 103.30,
  "conforming_indicator"                  => true,
  "debt_expense_ratio_percent"            => "27.261223",
  "loan_level_credit_score_value"         => 719.0,
  "financed_unit_count"                   => 1,
  "loan_purpose_type"                     => "Purchase",
  "property_usage_type"                   => "PrimaryResidence",
  "streamline_type"                       => "Not Streamlined",
  "fha_203k_indicator"                    => false,
  "project_legal_structure_type"          => nil,
  "refinance_cash_out_determination_type" => "NoCashOut",
  "escrow_indicator"                      => true,
  "pud_indicator"                         => false,
  "lock_type"                             => "Bulk",
  "division"                              => 'CLG',
}
#executes all .sql files in "*/lib/sample/data"
def load_plv_sql
      glb = Rails.root.to_s +
            '/lib/sample_data/*.sql'
      Dir.glob(glb).map do
        |sql_file|
        File.read(sql_file)
      end.each {|x| ActiveRecord::Base.connection.execute(x)}
    end

#
# Test prep and execution functions
#

# generates random test values based on keys/metadata
def generate_data_orig type, keys
  case type
  when "numrange", "int4range"
    keys.map!{|x| x.gsub(/\[|\]|\)|\(/, '').split(',')}
    keys = keys.flatten(1)
    range = [(keys.min == "" ? "0" : keys.min).to_i, keys.max.to_i]
    rand(range[0]..range[1])
  when "boolean"
    return [true, false][rand(0..1)]
  else
    return keys[rand(0...keys.length)][0]
  end
end

def generate_data type, keys_raw
  keys = keys_raw.compact
  klen = keys.count
  case type
  when "numrange", "int4range"
    cfn = type == "numrange" ? :to_f : :to_i
    ranges = keys.map { |k|
      range = k.split(',').map { |x| x.tr('[]()', '') }.map(&cfn)
      range[0] = 0 if range[0]==''
      range[1] = 100000000 if (range[0] > 0 && range[1] == 0)
      range
    }
    lambda { idx = rand(klen); rand(ranges[idx][0]..ranges[idx][1]) }
  when "boolean"
    lambda { [true, false][rand(0..1)] }
  else
    lambda { keys.empty? ? nil : keys[rand(klen)][0] }
  end
end

def not_so_random_grid id
  dg = Marty::DataGrid.where(id: id, obsoleted_dt: 'infinity').first
end

def get_random_grid
  dg = Marty::DataGrid.order("RANDOM()").limit(1).first
end

# generates test data using DataGrid metadata

@data = {}

def gen_test_data dg
  dg.metadata.each do |x|
    @data[[dg.id, x["attr"]]] = generate_data(x["type"], x["keys"])
  end
end
def get_test_data dg
  dg.metadata.each_with_object({}) do |x, h|
    attrname = x["attr"]
    h[attrname] = @data[[dg.id, attrname]].call
  end
end

def test_call(params, type = "rby")
  res = nil
  {type.upcase =>
   [Benchmark.realtime{ res = protected_call(params, type) }, res]}
end

def protected_call(params, type)
  begin
    ret = (type == "rby") ?
            Marty::DataGrid.lookup_grid(params[0],
                                        params[1],
                                        params[2],
                                        false) :
            Marty::DataGrid.plv_lookup_grid(params[0],
                                            params[1],
                                            params[2],
                                            false)
  rescue => e
    ret = "FAILURE: #{e.message}"
  end
  ret
end

def get_params id
  dg = (id == -1) ? get_random_grid : not_so_random_grid(id)
  pt = 'infinity'
  td = SAMPLE_LOAN + get_test_data(dg)
  params = [pt, dg, td]
end

def perform_test tn, rnd, id = -1
  params = get_params(id)
  case(tn)
  when "plv_first"
    plv = test_call(params, "plv")
    rby = test_call(params, "rby")
  when "rby_first"
    rby = test_call(params, "rby")
    plv = test_call(params, "plv")
  end
  rby_val = rby["RBY"][-1]
  plv_val = plv["PLV"][-1]
  rby_val = "failed" if rby_val.is_a?(String) &&
                        /FAILURE. DataGrid lookup failed/.match(rby_val)
  plv_val = "failed" if plv_val.is_a?(String) &&
                        /FAILURE. Error in PLV8 call.*lookup failed/.match(plv_val)
  info = {"RND"           => rnd,
          "test_name"     => tn,
          "equality"      => rby_val == plv_val,
          "datagrid_id"   => params[1].id,
          #"test_data"     => params[2]
         }
  info += { "result_rby" => rby["RBY"][-1],
            "result_plv" => plv["PLV"][-1]} if rby["RBY"][-1] != plv["PLV"][-1]

  binding.pry unless rby_val == plv_val
  [plv + info, rby + info]
end

def filter arr, key
  arr.select{|x| x[key] && (!x[key].include?("FAILURE"))}.map{|x| x[key][0]}
end

def average_time arr
  arr.inject{|sum, x| sum + x}.to_f/arr.size
end

#
# Test Script
#


def init_data
  Gemini::DataGrid.all.each { |dg| gen_test_data(dg) }
  true
end

def run_test(operations=1000)
  (puts "run init_data first"; return) if @data.empty?
  sttime = Time.now
  single_only = false

  unless single_only
    # perform a series of lookups based on random datagrids and random values
    # skip over errors for now and not count them in the timings
    random_times = []
    1.upto(operations) do |i|
        random_times.push(perform_test("plv_first", i))
        random_times.push(perform_test("rby_first", i))
    end
    random_times = random_times.flatten(1)
    plv_times    = filter(random_times, "PLV")
    rby_times    = filter(random_times, "RBY")
    plv_avg      = average_time(plv_times)
    rby_avg      = average_time(rby_times)

    random_results = "PLV VS RBY: random dg calls\n"\
                     "PLV: #{plv_avg}\n"\
                     "RBY: #{rby_avg}\n\n"\
                     "RBY/PLV ratio: #{rby_avg/plv_avg}\n\n"
  end

  # perform a series of lookups based on random values and a specific datagrid
  # skip over errors for now and not count them in the timings
  single_times = []
  1.upto(operations) do |i|
      single_times.push(perform_test("plv_first", i, 625))
      single_times.push(perform_test("rby_first", i, 625))
  end

  single_times = single_times.flatten(1)
  plv_times    = filter(single_times, "PLV")
  rby_times    = filter(single_times, "RBY")
  plv_avg      = average_time(plv_times)
  rby_avg      = average_time(rby_times)

  single_results  = "PLV VS RBY: single dg calls\n"\
                    "PLV: #{plv_avg}\n"\
                    "RBY: #{rby_avg}\n\n"\
                    "RBY/PLV ratio: #{rby_avg/plv_avg}\n\n"

  now = Time.now.strftime('%Y-%m-%d_%H-%M-%S')

  File.open("test_res/#{now}.txt", 'w+') do |f|
    f.puts "Operations: #{operations}\n\n"
    f.puts random_results unless single_only
    f.puts single_results
    f.puts random_times unless single_only
    f.puts single_times
  end

  File.open("test_res/object_single_#{now}.json", 'w+') do |f|
    f.puts single_times.to_json
  end

  File.open("test_res/object_random_#{now}.json", 'w+') do |f|
    f.puts random_times.to_json
  end unless single_only

  puts random_results unless single_only
  puts single_results
  t = Time.now - sttime
  ts = Time.at(t).utc.strftime("%H:%M:%S")
  puts "#{operations} calls total Time = #{ts}"
end
