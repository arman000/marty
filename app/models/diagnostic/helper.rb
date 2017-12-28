class Diagnostic::Helper
  include Delorean::Model

  delorean_fn :my_ip, sig:0 do
    Diagnostic::Node.my_ip
  end

  delorean_fn :git, sig:0 do
    [my_ip, ENV['DELAYED_VER']]
  end
end
