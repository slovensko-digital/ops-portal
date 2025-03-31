Rails.application.routes.draw do
  resources :clients

  namespace :connector do
    post "webhook" => "webhooks#webhook"
    namespace :backoffice do
      post "webhook" => "webhooks#webhook"
    end
  end

  namespace :triage do
    post "webhook" => "webhooks#webhook"
  end

  namespace "api", defaults: { format: :json } do
    namespace "v1" do
      resources :issues, only: [ :show, :update ] do
        resources :activities, only: [ :show, :create ], controller: "issues/activities"
      end
      resources :responsible_subjects do
        get :search, on: :collection
      end
    end
  end

  resources :issues, only: [ :index, :show, :destroy ]

  namespace :issues do
    resources :drafts do
      post :confirm
      scope module: :drafts do
        resource :suggestions do
          get :generate
        end
        resource :details
        resource :geo
        resource :checks do
          get :generate
        end
      end
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  mount GoodJob::Engine => "admin/good_job"

  # Defines the root path route ("/")
  root "issues/drafts#new"

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  get "*cms_slugs" => "cms/pages#index", as: :cms_page
end
