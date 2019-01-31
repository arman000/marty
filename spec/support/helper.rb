require 'delorean_lang'

module Marty; module RSpec;
  class Helper
    include Delorean::Model
    # Helper function which increments a global counter.  Can be used by
    # tests which run Delorean code to see how many times some code is
    # being called.  Works for rule scripts as well.
    delorean_fn :global_inc, sig: 1 do |inc|
      @@global_inc ||= 0

      if inc
        @@global_inc += inc
      else
        @@global_inc = 0
      end
    end
  end
end end
