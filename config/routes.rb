Rails.application.routes.draw do
  get "task_groups/show"
  resources :bill_shares
  resources :bills
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  get "dashboard-template" => "templates#index"
  get "about" => "about#index"
  get "home", to: "home#index"
  resources :chore_groups do
    resources :task_groups, only: [ :show ] do
      resources :tasks
    end
    resources :bills, only: [ :show, :create, :update, :destroy ] do
      resources :bill_shares, only: [ :create, :update, :destroy ]
    end
    member do
      post   :join
      delete :leave
    end
    collection do
      get :join
      get :new_chore_group
      get :search
      post :join
      post :search
    end

    resources :bills, only: [ :index, :new ]
  end
  resource :session, only: [ :new, :create, :destroy ]
  resource :password, only: [ :new, :create, :edit, :update ]

  resources :users
  resources :sessions, only: [ :new, :create, :destroy ]
  # resources :chore_groups
  resources :tasks
  resources :bills
  # root "chore_groups#index"
  # root "sessions#new"
  root "home#index"
end
