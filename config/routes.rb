Epm::Application.routes.draw do

  root 'events#index'

  devise_for :users
  resources :users, only: [:show, :edit, :update]

  resources :events do
    member do
      patch 'attend'
      patch 'unattend'
    end
  end

end
