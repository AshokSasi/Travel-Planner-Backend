Rails.application.routes.draw do
  get 'expenses/index'
  get 'expenses/create'
  get 'expenses/destroy'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
  namespace :api do
    get 'me', to: 'users#me'
    resources :users, only: [:index, :show, :create, :update, :destroy]
    post 'auth/signup', to: 'auth#signup'
    post 'auth/login', to: 'auth#login'
    post 'auth/google', to: 'auth#google'
    resources :trips, only: [:index, :create, :show, :destroy] do
      member do
        post 'generate_itinerary', to: 'itinerary_generator#generate'                 
        get 'balances', to: 'balances#balances'
        post 'join', to: 'trips#join'
        post 'send_join_email', to: 'trips#send_join_email'
        post 'regenerate_invite', to: 'trips#regenerate_invite'
        post 'leave_trip', to: 'trips#leave_trip'
      end
      resources :categories, only: [:index, :create, :update, :destroy]
      resources :settlements, only: [:index, :create]
      resources :expenses, only: [:index, :create, :update, :destroy, :show]
      resources :idea_cards, only: [:index, :create, :update, :destroy] do 
        resources :idea_upvotes, only: [:create, :destroy]
      end
      resources :itinerary_items, only: [:index, :update]
      resources :itinerary_days, only: [:index, :destroy, :create, :update]
    end
  end
end
