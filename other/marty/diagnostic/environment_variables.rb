module Marty::Diagnostic; class EnvironmentVariables < Base
  def self.env filter=''
    env = ENV.clone

    # obfuscate SECRET_KEY_BASE for comparison
    env['SECRET_KEY_BASE'] = env['SECRET_KEY_BASE'][0,4] if
      env['SECRET_KEY_BASE']

    # remove SCRIPT_URI, SCRIPT_URL as calling node differs
    ['SCRIPT_URI', 'SCRIPT_URL'].each{|k| env.delete(k)}

    to_block = ['PASSWORD', 'DEBUG']
    env.sort.each_with_object({}){|(k,v),h|
      h[k] = v if to_block.all?{|b| !k.include?(b)} && k.include?(filter)}
  end

  def self.generate
    pack do
      env
    end
  end

  # overwritten to only return inconsitent data
  def self.apply_consistency data
    diff = get_difference(data)
    data.each_with_object({}){
      |(node, diagnostic), new_data|
      new_data[node] = diagnostic.each_with_object({}){
        |(test, info), new_diagnostic|
        new_diagnostic[test] = info + {'consistent' => false} if
          diff.include?(test)
      }
    }
  end
end
end
