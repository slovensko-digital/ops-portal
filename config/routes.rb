Rails.application.routes.draw do
  resources :clients

  namespace :connector do
    post "webhook" => "webhooks#webhook"
    namespace :backoffice do
      post "webhook" => "webhooks#webhook"
    end
  end

  namespace :triage do
    namespace :webhooks do
      post :portal
      post :responsible_subject
    end
  end

  namespace :cms do
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

  resources :issues, path: "dopyty" do
    get :relevant, on: :collection, path: :r
    resource :issue_like, as: :like
    resource :issue_subscription, as: :subscription
    resources :issues_user_comments, path: "komentare", module: :issues
    resources :issues_user_private_comments, path: "komentare", module: :issues, controller: "issues_user_comments"
  end

  namespace :issues, path: "dopyty" do
    resources :drafts, path: "novy-dopyt", path_names: { new: "podnet" } do
      get :new_question, on: :collection, path: "otazka"
      delete :destroy_photo
      patch :rotate_photo
      get :thanks, on: :collection, path: "dakujeme"
      scope module: :drafts do
        resource :suggestions do
          get :generate
        end
        resource :details
        resource :geo
        resource :checks do
          get :generate
          post :confirm
        end
        resource :summary
        resource :category
        resource :subcategory
        resource :subtype
      end
    end

    resources :activities do
      resource :activity_vote, as: :vote
    end
  end

  resources :global_subscriptions, only: [] do
    collection do
      get "unsubscribe/:token", action: :unsubscribe, as: :unsubscribe
      post "unsubscribe/:token", action: :unsubscribe_post
    end
  end

  resources :subscriptions, only: [] do
    collection do
      get "unsubscribe/:token", action: :unsubscribe, as: :unsubscribe
    end
  end

  resources :uploads do
    patch :rotate, on: :member
  end

  resources :praises, path: "pochvaly", path_names: { new: "nova" } do
    collection do
      get "podakovanie", action: :thanks, as: "thanks"
    end
  end

  resource :profile, path: "profil" do
    collection do
      get :please_create, path: "potrebne-zalozit"
      get :please_verify, path: "potrebne-overit"
      get :watched_issues, path: "sledovane"
      get :verified_issues, path: "overene"
      get :settings, path: "nastavenia"
    end
    resource :avatar, module: :profiles
    resource :verification, module: :profiles do
      get :code
      post :check_code
    end
  end

  resources :users, path: "pouzivatelia"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest, defaults: { format: :json }
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "homepage#show"

  # legacy urls redirects
  get "r/:municipality_slug" => "legacy/redirects#index"
  get "r/:municipality_slug/vsetky-podnety" => "legacy/redirects#search_list"
  get "r/:municipality_slug/statistiky" => "legacy/redirects#search_stats"
  get "r/:municipality_slug/podnety/:legacy_id/:slug" => "legacy/redirects#show_issue"
  get "r/:municipality_slug/pridat-podnet" => "legacy/redirects#create_issue"

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
  mount GoodJob::Engine => "admin/good_job" # TODO authenticate!

  constraints lambda { |req| !req.xhr? && req.format.html? && (req.path =~ %r{^/(rails|assets)/}).nil? } do
    get "*path" => "cms/pages#index", as: :cms_page
  end
end
