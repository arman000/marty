require 'delorean_lang'

class Gemini::Helper
  include Delorean::Model

  # Just for testing
  delorean_fn :sleep, sig: 1 do
    |seconds|
    Kernel.sleep seconds
  end
end
