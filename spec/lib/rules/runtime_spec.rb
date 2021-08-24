require 'spec_helper'

RSpec.describe Marty::Rules::Runtime do
  let(:script1) do
    file_fixture('misc/rules/test_script_1.js').read
  end

  let(:script2) do
    file_fixture('misc/rules/test_script_2.js').read
  end

  let(:script3) do
    file_fixture('misc/rules/test_script_3.js').read
  end

  let(:script_with_timeout) do
    file_fixture('misc/rules/test_script_with_timeout.js').read
  end

  let(:script_with_memory_issue) do
    file_fixture('misc/rules/test_script_with_memory_issue.js').read
  end

  let(:script_with_exception) do
    file_fixture('misc/rules/test_script_with_exception.js').read
  end

  let(:zeus_script_1) do
    file_fixture('misc/rules/zeus_script1.js').read
  end

  def create_package(name: 'test-package', starts_at:, script:, metadata: {})
    Marty::Rules::Package.create!(
      name: name,
      build_name: "build #{starts_at}",
      starts_at: starts_at,
      script: script,
      metadata: metadata
    ).reload
  end

  let!(:package1) do
    create_package(
      starts_at: 3.hours.ago,
      script: script1,
      metadata: { input_fields: %w[a b c] }
    )
  end

  let!(:package2) do
    create_package(
      starts_at: 2.hours.ago,
      script: script2,
      metadata: { input_fields: %w[d e f] }
    )
  end

  let!(:package3) do
    create_package(
      starts_at: 1.hour.ago,
      script: script3,
      metadata: { input_fields: %w[x y z] }
    )
  end

  let(:package_with_timeouts) do
    create_package(
      starts_at: 5.hours.ago,
      script: script_with_timeout
    )
  end

  let(:package_with_memory_issue) do
    create_package(
      starts_at: 3.hours.ago,
      script: script_with_memory_issue
    )
  end

  let(:package_with_exception) do
    create_package(
      starts_at: 30.hours.ago,
      script: script_with_exception
    )
  end

  let(:zeus_package1) do
    create_package(
      starts_at: 33.hours.ago,
      script: zeus_script_1
    )
  end

  let!(:runtime1) do
    described_class.new(
      package_name: 'test-package',
      memory_limit_mb: 10,
      timeout_seconds: 2
    )
  end

  let(:zeus_package1_input1) do
    {
      'order' => {
        'products' => [
          { 'name' => 'Water', 'price' => 100.5, 'amount' => 1 },
          { 'name' => 'Hot dog', 'price' => 10, 'amount' => 1 }
        ],
         'total_price' => 110.5
      },
     'users' => [
       { 'age' => 25, 'state' => 'CA', 'lastname' => 'Doe', 'firstname' => 'John' },
       { 'age' => 42, 'state' => 'NY', 'lastname' => 'Adams', 'firstname' => 'Arthur' }
     ],
     'total_price' => 110.5
    }
  end

  let(:zeus_package1_output1) do
    {
      'all' => [
        { 'total_price' => 222.2, '__metadata__' => { 'rule_name' => 'Rule1' } },
        { 'total_price' => 223.2, '__metadata__' => { 'rule_name' => 'Rule2' } },
        { 'total_price' => 224.2, '__metadata__' => { 'rule_name' => 'Rule3 With Guards' } }
      ],
       'state' => 'SC',
       'total_price' => 222.2
    }
  end

  describe 'historical Rules' do
    it 'adds historical v8' do
      expect(runtime1.historical_v8).to be_present

      res = runtime1.call(pt: 2.hours.ago + 1.second, hash: { amount: 1.5 })
      expect(res).to eq(
        {
          'metadata' => { 'message' => 'test_script_2#call was called' },
          'result' => 11.5
        }
      )
    end

    it 'loads missing package' do
      expect(runtime1.historical_v8.packages).to be_empty
      res = runtime1.call(pt: package2.starts_at + 1.second, hash: { amount: 1 })

      expect(runtime1.historical_v8.packages).to include(package2.starts_at)

      expect(res).to eq(
        {
          'metadata' => { 'message' => 'test_script_2#call was called' },
          'result' => 11
        }
      )
    end

    it 'raises error if package is not found' do
      expect(runtime1.historical_v8.packages).to be_empty

      expect do
        runtime1.call(pt: 10.days.ago, hash: { amount: 1 })
      end.to raise_error(
        Marty::Rules::Errors::PackageNotFound,
        /Package test-package with starting date before .* was not found/
      )
    end

    it 'evaluates package rules' do
      res = runtime1.call(pt: package1.starts_at + 1.second, hash: { amount: 1 })
      expect(runtime1.historical_v8.packages).to include(package1.starts_at)

      expect(res).to eq(
        {
          'metadata' => { 'message' => 'test_script_1#call was called' },
          'result' => 11
        }
      )
    end
  end

  describe 'latest rules' do
    it 'adds latest v8' do
      expect(runtime1.current_v8).to be_present
      expect(runtime1.current_v8.packages).to be_present
    end

    it 'loads newer package if one exists' do
      expect(runtime1.current_v8.packages).to include(package3.starts_at)

      newer_package = create_package(
        starts_at: 1.minute.ago,
        script: script3
      )

      runtime1.call(pt: Time.zone.now, hash: { amount: 1 })

      expect(runtime1.current_v8.packages).to include(newer_package.starts_at)
    end

    it 'raises error if package is not found' do
      runtime = described_class.new(
        package_name: 'test-package-2',
        memory_limit_mb: 1,
        timeout_seconds: 2
      )

      pt = Time.zone.now
      expect do
        runtime.call(pt: pt, hash: { amount: 1 })
      end.to raise_error(
        Marty::Rules::Errors::PackageNotFound,
        /Package test-package-2 with starting date before .* was not found/
      )
    end
  end

  describe 'common' do
    it 'handes an error if memory limit is exceeded when package is loaded' do
      100.times do |i|
        # FIXME: V8's garbage collecting is nondeterministic, so normal script
        # might not trigger GC and therefore not have a Memory limit exception thrown in CI.
        #
        # Apparently, iterating over an array increases the chance of GC so
        # we can use it as a hack to get consistent behaviour.
        script = "a = Array.from(new Array(100000)).map((e) => e + 1); #{script1}"

        runtime1.historical_v8.load_package(
          package: {
            'starts_at' => Time.zone.now + i.seconds,
            'script' => script
          }
        )
      end

      expect(
        runtime1.historical_v8.v8.heap_stats[:total_physical_size]
      ).to be < runtime1.memory_limit_mb * 3_000_000

      expect(runtime1.historical_v8.packages.size).to be < 90
    end

    it 'can read package metadata' do
      times = [
        Time.zone.now,
        Time.zone.now - 30.minutes,
        Time.zone.now - 1.hour + 1.second,
        2.hours.ago + 1.second,
        3.hours.ago + 1.second
      ]
      aggregate_failures do
        times.each do |time|
          res = runtime1.metadata(pt: time)
          exp = Marty::Rules::Package.where('starts_at <= ?', time).
                  order(starts_at: :desc)&.first&.metadata
          expect(res).to eq(exp)
        end
        errexp =
          /Package test-package with starting date before .* was not found/
        expect { runtime1.metadata(pt: 10.hours.ago) }.to raise_error(errexp)
      end
    end

    it 'raises an error if memory limit is exceeded' do
      pt = package_with_memory_issue.starts_at + 1.second

      expect do
        runtime1.call(pt: pt, hash: { amount: 1 })
      end.to raise_error(MiniRacer::V8OutOfMemoryError)

      # Check that package was loaded again before the second attempt
      expect(
        runtime1.historical_v8.packages
      ).to include(package_with_memory_issue.starts_at)

      logs = Marty::Log.where("message ILIKE '%Marty::Rules::Runtime%'")

      expect(logs.size).to eq(1)
      expect(logs.first.details).to include(
        {
          'error_class' => 'MiniRacer::V8OutOfMemoryError',
         'package_name' => 'test-package: historical'
        }
      )
    end

    it 'timeouts' do
      pt = package_with_timeouts.starts_at + 1.second
      expect do
        runtime1.call(pt: pt, hash: { amount: 1 })
      end.to raise_error(MiniRacer::ScriptTerminatedError)
    end

    it 'raises error if package is invalid' do
      expect do
        runtime1.historical_v8.load_package(
          package: {
            'starts_at' => Time.zone.now,
          'script' => 'invalid(script)'
          }
        )
      end.to raise_error(
        MiniRacer::RuntimeError,
        'ReferenceError: invalid is not defined'
      )
    end

    it 'handles errors from package' do
      pt = package_with_exception.starts_at + 1.second

      expect do
        runtime1.call(pt: pt, hash: { amount: 1 })
      end.to raise_error(
        MiniRacer::RuntimeError,
        /Test error/
      )
    end

    it 'runs zeus script 1' do
      res = runtime1.call(pt: zeus_package1.starts_at + 1.second, hash: zeus_package1_input1)
      expect(runtime1.historical_v8.packages).to include(zeus_package1.starts_at)

      expect(res).to eq(zeus_package1_output1)
    end
  end
end
