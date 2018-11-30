StellarMultisig::Rails::Engine.routes.draw do
  scope module: 'rails' do
    namespace :api do
      namespace :v1 do
        resources :totp, only: [:create]
      end
    end
  end
end
