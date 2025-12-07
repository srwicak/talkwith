Rails.application.routes.draw do
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "schedules/bookings#new"

  scope module: :schedules do
    resources :bookings
    resources :appointments, param: :slug, only: %i[show update] do
      member do
        get :download_ics
        get :cancel
      end
    end
  end

  # UDI x ITB Special Booking Routes
  get '/udi-booking', to: 'schedules/udi_bookings#new', as: 'udi_booking'
  post '/udi-booking', to: 'schedules/udi_bookings#create'
  get '/udi-booking/slots', to: 'schedules/udi_bookings#available_slots'

  scope "/" do
    # Google Calendar Management - unified route
    get "manage", to: "manages#index", as: "manage_appointments"
    resources :manages, only: [] do
      member do
        patch :approve
        delete :reject
      end
      collection do
        post :sync_from_google
        post :sync_to_google
      end
    end

    # UDI Settings Management
    namespace :manages do
      resources :udi_settings, only: [:index] do
        collection do
          patch :update_slots
          post :reset_week
          post :disable_all_week
        end
      end

      # UDI Configuration Management (Day & Time Settings)
      resources :udi_configurations do
        member do
          patch :toggle_enabled
        end
      end
      
      # OAuth2 Setup for Google Meet (Gmail B)
      get 'oauth/setup', to: 'oauth#setup', as: 'oauth_setup'
      post 'oauth/callback', to: 'oauth#callback', as: 'callback_oauth'
      post 'oauth/reset', to: 'oauth#reset', as: 'reset_oauth'
    end

    get "appointments", to: redirect("/")

    get "signin", to: "users/sessions#new", as: "new_user_session"
    post "signin", to: "users/sessions#create", as: "user_session"

    delete "signout", to: "users/sessions#destroy", as: "destroy_user_session"

    get "signup", to: "users/registrations#new", as: "new_user_registration"
    # post "signup", to: "users/registrations#create", as: "user_registration"
  end
end
