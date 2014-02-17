Epm::Application.routes.draw do

  devise_for :users

  root 'events#index'

  resources :events do
    patch 'attend', on: :member
  end

end
