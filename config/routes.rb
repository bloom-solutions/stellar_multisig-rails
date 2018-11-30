StellarMultisig::Rails::Engine.routes.draw do
  scope module: 'rails' do
    namespace :api do
      namespace :v1 do
        resources :totp, only: [:create] do
          collection do
            post 'verify'
          end
        end
      end
    end
  end
end
