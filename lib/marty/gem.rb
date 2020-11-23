module Marty
  # This module caches the +Gem::Specification+ of Marty, and provides
  # additional helper methods for requiring. It allows direct access to
  # all of the specification methods using {.method_missing}.
  module Gem
    # The cached Marty +Gem::Specification+
    SPEC = ::Gem::Specification.find_by_name('marty') # rubocop:disable Rails/DynamicFindBy

    # Cached +Pathname+ of the Marty gem directory
    @dir_pathname = Pathname.new(SPEC.gem_dir)

    module_function

    # @return [Pathname] Marty's directory.
    def dir
      @dir_pathname
    end

    # @return [Pathname] Marty's delorean directory.
    def delorean_dir
      @dir_pathname.join('delorean')
    end

    # @return [Pathname] Marty's spec directory.
    def spec_dir
      @dir_pathname.join('spec')
    end

    # Requires a file relative to the current {.dir}.
    #
    # @param filename [String] The file to require inside of {.dir}
    # @return [Boolean]
    def require_file!(filename)
      require dir.join(filename)
    end

    # Proxies all methods to {SPEC}.
    def method_missing(method_name, *args, &block)
      SPEC.send(method_name, *args, *block)
    end

    def respond_to_missing?(method_name, include_private = false)
      SPEC.respond_to?(method_name) || super
    end
  end
end
