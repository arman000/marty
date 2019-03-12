module Marty::Diagnostic; class EnvironmentVariables < Base
  diagnostic_fn do
    env
  end

  def self.env filter = ''
    env = ENV.clone

    to_delete = (Marty::Config['DIAG_ENV_BLOCK'] || []).map(&:upcase) + [
      'SCRIPT_URI', 'SCRIPT_URL'
    ]

    to_obfus = (Marty::Config['DIAG_ENV_OBFUSCATE'] || []).map(&:upcase) + [
      'SECRET_KEY_BASE'
    ]

    to_block = (Marty::Config['DIAG_ENV_BLOCK_IF_INCL'] || []).map(&:upcase) + [
      'ACCESS', 'SECRET', 'PASSWORD', 'DEBUG'
    ]

    to_delete.each { |k| env.delete(k) }

    to_obfus.each { |k| env[k] = env[k][0, 4] if env[k] }

    env.sort.each_with_object({}) do |(k, v), h|
      h[k] = v if to_block.all? { |b| !k.include?(b) } && k.include?(filter)
    end
  end

  # overwritten to only return inconsitent data
  def self.apply_consistency data
    diff = get_difference(data)
    data.each_with_object({}) do |(node, diagnostic), new_data|
      new_data[node] = diagnostic.each_with_object({}) do |(test, info), new_diagnostic|
        new_diagnostic[test] = info + { 'consistent' => false } if
          diff.include?(test)
      end
    end
  end
end
end
