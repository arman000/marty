require 'job_helper'

describe Marty::Diagnostic::Reporter do
  def params(diagnostic = 'base', scope = nil)
    { op: diagnostic, scope: scope }
  end

  def git
      message = Marty::Diagnostic::Git.tag
  rescue StandardError
      message = error('Failed accessing git')
  end

  def aggregate_data(opts = {})
    {
      'Dummy' => {
        'NodeA' => {
          'ImportantTest' => {
            'description' => 'A',
            'status' => opts[:status].nil? ? true : opts[:status],
            'consistent' => opts[:consistent].nil? ? true : opts[:consistent],
          }
        }
      }
    }
  end

  def aggregate_consistency_data(diagnostic = 'Base')
    original_a = Marty::Diagnostic::Base.create_info('A')
    original_b = Marty::Diagnostic::Base.create_info('B')

    data = {
      'CONSTANTA' => original_a,
      'CONSTANTB' => original_b,
      'CONSTANTB2' => original_b,
    }

    different_b = Marty::Diagnostic::Base.create_info('C')

    test = {
      diagnostic => {
        'NodeA' => data,
        'NodeB' => data + {
          'CONSTANTB' => different_b,
          'CONSTANTB2' => different_b
        },
      }
    }

    inconsistent_b = Marty::Diagnostic::Base.create_info('B', true, false)
    inconsistent_c = Marty::Diagnostic::Base.create_info('C', true, false)

    expected = if diagnostic == 'EnvironmentVariables'
                {
                  diagnostic => {
                    'NodeA' => {
                      'CONSTANTB' => inconsistent_b,
                      'CONSTANTB2' => inconsistent_b,
                    },
                    'NodeB' => {
                      'CONSTANTB' => inconsistent_c,
                      'CONSTANTB2' => inconsistent_c,
                    },
                  }
                }
               else
                {
                  diagnostic => {
                    'NodeA' => {
                      'CONSTANTA' => original_a + { 'consistent' => true },
                      'CONSTANTB' => inconsistent_b,
                      'CONSTANTB2' => inconsistent_b,
                    },
                    'NodeB' => {
                      'CONSTANTA' => original_a + { 'consistent' => true },
                      'CONSTANTB' => inconsistent_c,
                      'CONSTANTB2' => inconsistent_c,
                    },
                  }
                }
               end
    [test, expected]
  end

  def info(v, status, consistent)
    Marty::Diagnostic::Base.create_info(v, status, consistent)
  end

  def version_data(consistent = true)
    Marty::Diagnostic::Base.pack(include_ip = false) do
      {
        'Marty'    => info(Marty::VERSION, true, consistent),
        'Delorean' => info(Delorean::VERSION, true, true),
        'Mcfly'    => info(Mcfly::VERSION, true, true),
        'Git'      => info(git, true, true),
      }
    end
  end

  def minimize(str)
    str.gsub(/\s+/, '')
  end

  describe 'display mechanism for version diagnostic' do
    it 'masks consistent nodes for display (version)' do
      data = {
        'Version' => {
          'NodeA' => version_data,
          'NodeB' => version_data,
        }
      }

      expected = <<-ERB
      <h3>Version</h3>
      <div class="wrapper">
        <table>
          <tr>
            <th colspan="2" scope="col">consistent</th>
          </tr>
          <tr>
            <th class="data" scope="row">Marty</th>
            <td class="overflow passed"><p>#{Marty::VERSION}</p>
            </td>
          </tr>
          <tr>
            <th class="data" scope="row">Delorean</th>
            <td class="overflow passed"><p>#{Delorean::VERSION}</p>
            </td>
          </tr>
          <tr>
            <th class="data" scope="row">Mcfly</th>
            <td class="overflow passed"><p>#{Mcfly::VERSION}</p>
            </td>
          </tr>
          <tr>
            <th class="data" scope="row">Git</th>
            <td class="overflow passed"><p>#{git}</p>
            </td>
          </tr>
        </table>
      </div>
      ERB

      reporter = described_class.new
      reporter.result = data
      reporter.scope = 'local'
      expect(minimize(reporter.display['html'])).to eq(minimize(expected))
    end

    it 'displays all nodes when there is an inconsistent node (version)' do
     bad_ver = '0.0.0'
     expected = <<-ERB
      <h3>Version</h3>
      <h3 class="error">Inconsistency Detected </h3>
      <div class="wrapper">
      <table>
         <tr>
            <th></th>
            <th scope="col">NodeA</th>
            <th scope="col">NodeB</th>
          </tr>
          <tr>
            <th class="data" scope="row">Marty</th>
            <td class="overflow inconsistent"><p>#{Marty::VERSION}</p></td>
            <td class="overflow inconsistent"><p>#{bad_ver}</p></td>
          </tr>
          <tr>
            <th class="data" scope="row">Delorean</th>
            <td class="overflow passed"><p>#{Delorean::VERSION}</p></td>
            <td class="overflow passed"><p>#{Delorean::VERSION}</p></td>
          </tr>
          <tr>
            <th class="data" scope="row">Mcfly</th>
            <td class="overflow passed"><p>#{Mcfly::VERSION}</p></td>
            <td class="overflow passed"><p>#{Mcfly::VERSION}</p></td>
          </tr>
          <tr>
            <th class="data" scope="row">Git</th>
            <td class="overflow passed"><p>#{git}</p></td>
            <td class="overflow passed"><p>#{git}</p></td>
          </tr>
      </table>
      </div>
     ERB

     reporter = described_class.new
     reporter.result = {
       'Version' => {
         'NodeA' => version_data(consistent = false),
         'NodeB' => version_data + {
           'Marty' => Marty::Diagnostic::Base.create_info(bad_ver, true, false)
         },
       }
     }

     reporter.scope = 'local'
     result = reporter.display['html']
     expect(minimize(result)).to eq(minimize(expected))
    end

    it 'can detect errors in diagnostic for display and api' do
      n = aggregate_data
      e = aggregate_data(status: false)
      c = aggregate_data(consistent: false)
      ce = aggregate_data(status: false, consistent: false)

      aggregate_failures do
        expect(described_class.errors(n)).to eq({})
        expect(described_class.errors(e)).not_to eq({})
        expect(described_class.errors(c)).not_to eq({})
        expect(described_class.errors(ce)).not_to eq({})
      end
    end

    it 'can survive and display fatal errors' do
      a_err_a = Marty::Diagnostic::Fatal.message('A',
                                                 node: 'NodeA')

      a_err_b = Marty::Diagnostic::Fatal.message('B',
                                                 node: 'NodeA')

      b_err_c = Marty::Diagnostic::Fatal.message('C',
                                                 node: 'NodeB',
                                                 type: 'OtherError')

      c_err_d = Marty::Diagnostic::Fatal.message('D',
                                                 node: 'NodeC',
                                                 type: 'OtherOtherError')

      data = [a_err_a, a_err_b, b_err_c, c_err_d].reduce(:deep_merge)

      expected = <<-ERB
      <h3>Fatal</h3>
      <h3 class="error">Inconsistency Detected</h3>
      <div class="wrapper">
        <table>
          <tr>
            <th></th>
            <th scope="col">NodeA</th>
            <th scope="col">NodeB</th>
            <th scope="col">NodeC</th>
          </tr>
          <tr><th class="data" scope="row">RuntimeError</th>
            <td class="overflow error">
              <p>B</p>
            </td>
            <td class="overflow inconsistent">
              <p>N/A</p>
            </td>
            <td class="overflow inconsistent">
              <p>N/A</p>
            </td>
          </tr>
          <tr><th class="data" scope="row">OtherError</th>
            <td class="overflow inconsistent">
              <p>N/A</p>
            </td>
            <td class="overflow error">
              <p>C</p>
            </td>
            <td class="overflow inconsistent">
              <p>N/A</p>
            </td>
          </tr>
          <tr><th class="data" scope="row">OtherOtherError</th>
            <td class="overflow inconsistent">
              <p>N/A</p>
            </td>
            <td class="overflow inconsistent">
              <p>N/A</p>
            </td>
            <td class="overflow error">
              <p>D</p>
            </td>
          </tr>
        </table>
      </div>
      ERB

      reporter = described_class.new
      reporter.scope = 'local'
      reporter.result = data
      expect(minimize(reporter.display['html'])).to eq(minimize(expected))
    end
  end

  describe 'aggregation consistency functionality' do
    it 'env diagnostic' do
      result, expected = aggregate_consistency_data('EnvironmentVariables')
      expect(described_class.consistency(result)).to eq(expected)
    end

    it 'marks data as consistent/inconsistent' do
      result, expected = aggregate_consistency_data
      expect(described_class.consistency(result)).to eq(expected)
    end
  end
end
