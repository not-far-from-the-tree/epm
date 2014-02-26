Epm::Application.routes.draw do

  root 'events#index'

  devise_for :users
  resources :users, only: [:show, :edit, :update] do
    patch 'add_role', on: :member
  end

  resources :events do
    member do
      patch 'attend'
      patch 'unattend'
    end
  end

end
