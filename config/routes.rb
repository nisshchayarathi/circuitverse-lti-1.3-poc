Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  # --- LTI 1.3 Tool Provider (POC) ---
  # Public JWKS endpoint (used for tool registration / key discovery).
  get "/jwks.json", to: "lti#jwks"

  # OIDC login initiation endpoint (platform -> tool). Some platforms use GET.
  match "/lti/oidc/login", to: "lti#login", via: %i[get post]

  # OIDC redirect / launch callback (platform -> tool) using response_mode=form_post.
  post "/lti/oidc/callback", to: "lti#callback"
end
