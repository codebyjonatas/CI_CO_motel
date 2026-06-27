Rails.application.routes.draw do
  devise_for :users

  resources :rooms
  resources :stays do
   member do
      patch :check_out
      patch :cancel
    end
end

  authenticated :user do
    root "stays#index", as: :authenticated_root
  end

  unauthenticated do
    root "home#index"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
