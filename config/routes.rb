Rails.application.routes.draw do
  # Gateway endpoint
  namespace :gateway do
    resources :transactions, only: [:create]
  end

  # User-facing endpoint
  get 'transactions/auth/:id', to: 'transactions#auth', as: :transactions_auth
end
