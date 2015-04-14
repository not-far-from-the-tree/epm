Epm::Application.routes.draw do

  root 'events#index'

  devise_for :users, controllers: { registrations: 'registrations' }
  resources :users, only: [:index, :show, :edit, :update] do
    resources :roles, only: [:create, :destroy], shallow: true
    get 'map', on: :collection
    patch 'deactivate', on: :member
  end
  get 'me', to: 'users#me'
  get 'my_wards', to: 'users#my_wards'

  resources :events do
    get 'calendar', on: :collection
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
    get 'closest', on: :collection
  end   

  get 'geocode', to: 'geocode#index'

end