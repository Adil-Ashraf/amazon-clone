Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resource :session, only: %i[new create destroy]
  resource :registration, only: %i[new create]
  resource :account, only: %i[show]

  resources :search_suggestions, only: %i[index]
  resources :products, only: %i[index show] do
    resources :reviews, only: %i[create]
  end

  resource :cart, only: %i[show]
  resources :cart_items, only: %i[create update destroy] do
    member { post :save_for_later }
  end
  resources :wishlist_items, only: %i[index create destroy], path: "wishlist"

  resource :checkout, only: %i[new create]
  resources :orders, only: %i[index show]

  resources :newsletter_subscriptions, only: %i[create]
  get "pages/:page", to: "pages#show", as: :page, constraints: { page: Regexp.union(PagesController::PAGES) }

  # Defines the root path route ("/")
  root "home#show"
end
