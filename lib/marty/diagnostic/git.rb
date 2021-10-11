module Marty
  module Diagnostic
    module Git
      module_function

      def root
        Rails.root || '.'
      end

      def tag
        git_tag = `cd #{root}; git describe --tags --always --abbrev=7;`.strip
        git_datetime = `cd #{root}; git log -1 --format=%cd;`.strip
        "#{git_tag} (#{git_datetime})"
      end

      def submodules
        submodules = `cd #{root}; git submodule`.split("\n").map do |s|
          sha, path, tag = s.split
          name = File.basename(path)
          {
            "#{name}_sha".titleize => sha[0..7],
            "#{name}_tag".titleize => tag,
          }
        end.reduce(&:merge) || {}
      end
    end
  end
end
