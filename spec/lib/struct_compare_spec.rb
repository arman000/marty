require 'spec_helper'

describe "StructCompare" do
  it "compares correctly" do
    p = File.expand_path('../../fixtures/misc', __FILE__)
    fname = "%s/%s" % [p, 'struct_compare_tests.txt']
    aggregate_failures 'struct_compare' do
      data = JSON.parse(File.read(fname))
      data.each do |ex|
        args = [ex["v1"], ex["v2"], ex['cmp_opts']].compact
        comp = struct_compare(*args)
        comparison = comp.nil? ? false : comp
        num = ex["example_number"]
        binding.pry if comparison != ex['res']
        expect(comparison).to eq(ex["res"]), "Test ##{num} failed: #{comparison}"
      end
    end
  end
end
