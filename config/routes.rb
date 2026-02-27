Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  namespace :api do
    get 'me', to: 'users#me'
    resources :users, only: [:index, :show, :create, :update]
    post 'auth/signup', to: 'auth#signup'
    post 'auth/login', to: 'auth#login'
    post 'auth/google', to: 'auth#google'
    resources :trips, only: [:index, :create, :show] do
      member do
        post 'join', to: 'trips#join'
        post 'send_join_email', to: 'trips#send_join_email'
        post 'regenerate_invite', to: 'trips#regenerate_invite'
      end
      resources :idea_cards, only: [:index, :create, :update, :destroy]
      resources :itinerary_items, only: [:index, :update]
      resources :itinerary_days, only: [:index, :destroy, :create]
    end
  end
end
