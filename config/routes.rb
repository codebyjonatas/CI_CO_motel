Rails.application.routes.draw do
  devise_for :users, skip: :registration

  # Dashboard global de comandas (fora do namespace de rooms)
  get "comandas", to: "tabs#dashboard", as: :tabs_dashboard

  # Relatórios de faturamento do bar
  get "relatorios", to: "tabs#report", as: :tabs_report

  resources :rooms do
    member do
      patch :start_cleaning
      patch :finish_cleaning
      patch :release_quarantine
      get :history
    end
    resources :tabs, only: [ :index, :new, :create, :show ] do
      member do
        patch :close
        patch :pay
        patch :cancel
        patch :transfer
        patch :apply_discount
      end
      collection do
        post :create_walk_in
      end
      resources :tab_items, only: [ :create ] do
        member do
          patch :void
          patch :update_quantity
        end
      end
    end
  end

  resources :stays do
    member do
      patch :check_out
      patch :cancel
      get :info
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
