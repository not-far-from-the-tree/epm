Epm::Application.routes.draw do

  resources :agencies

  resources :equipment_sets

  root 'events#dashboard'

  devise_for :users, controllers: { registrations: 'registrations' }
  resources :users, only: [:index, :show, :edit, :update, :destroy] do
    resources :roles, only: [:create, :destroy], shallow: true
    get 'map', on: :collection
    patch 'deactivate', on: :member
    get 'invite'
  end
  get 'me', to: 'users#me'
  get 'my_wards', to: 'users#my_wards'

  resources :events do
    get 'calendar', on: :collection
    get 'dashboard', on: :collection
    member do
      get 'who'
      get 'cancel', to: 'events#ask_to_cancel'
      patch 'cancel'
      patch 'approve'
      patch 'claim'
      patch 'unclaim'
      patch 'attend'
      patch 'unattend'
      patch 'invite'
      patch 'take_attendance'
    end
  end

  # for configurable_engine gem; it generates its own routes as well which are unused
  put 'settings', to: 'settings#update', as: 'settings'
  get 'settings', to: 'settings#show'

  resources :trees do
    get 'mine', on: :collection
    get 'closest', on: :collection
  end   

  get 'geocode', to: 'geocode#index'

end