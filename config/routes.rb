Rails.application.routes.draw do
  namespace :ovm_connector, path: "ovm-connector" do
    namespace :webhooks do
      post "triage/ticket-created"
    end
  end

  namespace :webhooks do
    post "ticket-created"
    post "ticket-status-changed"
    post "article-created"
  end

  namespace "api" do
    namespace "v1" do
    end
  end

  resources :issues
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
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "issues/drafts#new"
end
