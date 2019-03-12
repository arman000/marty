require 'rspec'

RSpec::Matchers.define :netzke_include do |expected|
  match do |actual|
    parsed_values = actual.each_with_object({}) do |(k, v), h|
      h[k] = v == 'False' ? false : v
    end
    expect(parsed_values).to include(expected.stringify_keys)
  end

  diffable
end

RSpec::Matchers.define :match_fuzzily do |expected|
  msg = nil
  match { |actual| !(msg = struct_compare(actual, expected)) }
  failure_message { |_| msg }
end
