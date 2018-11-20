StellarMultisig::Rails::Engine.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :totp, only: [:index]
    end
  end
end
