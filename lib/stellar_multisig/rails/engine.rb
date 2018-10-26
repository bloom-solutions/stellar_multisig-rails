module StellarMultisig
  module Rails
    class Engine < ::Rails::Engine
      isolate_namespace StellarMultisig::Rails
    end
  end
end
