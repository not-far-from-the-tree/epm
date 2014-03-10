Epm::Application.routes.draw do

  root 'events#index'

  devise_for :users
  resources :users, only: [:index, :show, :edit, :update] do
    patch 'add_role', on: :member
  end

  resources :events do
    get 'past', on: :collection
    member do
      patch 'attend'
      patch 'unattend'
    end
  end

  # for configurable_engine gem; it generates its own routes as well which are unused
  put 'settings', to: 'settings#update', as: 'settings'
  get 'settings', to: 'settings#show'

end