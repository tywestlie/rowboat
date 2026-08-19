Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Confirmed exoplanets and their host stars, the app's one focused experience
  # (read-only, no auth yet)
  get "systems", to: "systems#index"
  get "systems/:hostname", to: "systems#show", as: :system

  get "exoplanets/random", to: "exoplanets#random", as: :random_exoplanet
  resources :exoplanets, only: [ :index, :show ]

  get "extremes", to: "extremes#index"

  # AI-powered natural-language query feature, gated by a session-based access code
  get "ask/access", to: "ai_access#new", as: :new_ai_access
  post "ask/access", to: "ai_access#create", as: :ai_access

  get "ask", to: "questions#new", as: :ask
  resources :questions, only: [ :create, :show ]

  # Defines the root path route ("/")
  root "home#index"
end
