Rails.application.routes.draw do
  mount StellarMultisig::Rails::Engine => "/stellar_multisig-rails"
end
