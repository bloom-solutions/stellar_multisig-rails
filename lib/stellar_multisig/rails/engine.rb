module StellarMultisig
  module Rails
    class Engine < ::Rails::Engine
      isolate_namespace StellarMultisig
      engine_name "stellar_multisig"
    end
  end
end
