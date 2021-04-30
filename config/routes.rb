require 'sidekiq/web'

Rails.application.routes.draw do
  # Disallow registration, wire up custom devise sessions controller
  devise_for :users, skip: [:registrations], controllers: { sessions: :sessions }

  devise_scope :user do
    # Manually re-creates routes for editing users
    get 'users/edit' => 'devise/registrations#edit', as: :edit_user_registration
    put 'users' => 'devise/registrations#update', as: :user_registration
  end

  namespace :admin do
    resources :basic_projects, path: 'basic-projects' do
      member do
        get :duplicate
      end
    end
    resources :calendar, only: [:index]
    resources :calendar_events, only: [:index]
    resources :data_exports, path_names: {new: '(/:type)/new'}, path: "data-exports"
    resources :response_sets
    resources :divisions do
      collection do
        post :select
      end
    end
    resources :loans do
      member do
        get :questionnaires
        get :print
        get :duplicate
      end
    end
    resources :questions do
      patch 'move', on: :member
    end
    resources :notes, only: [:create, :update, :destroy]
    resources :organizations
    resources :people
    resources :projects do
      member do
        get :steps
        patch :change_date
        get :timeline
      end
    end
    resources :project_logs, path: 'logs'
    resources :project_steps do
      collection do
        patch :batch_destroy
        patch :adjust_dates
        patch :finalize
      end
      member do
        post :duplicate
        get :show_duplicate
      end
    end
    resources :project_groups
    resources :tasks
    resources :timeline_step_moves do
      member do
        patch :simple_move
      end
    end

    authenticate :user, lambda { |u| u.has_role?(:admin, Division.root) } do
      mount Sidekiq::Web => '/jobs'
    end

    scope '/:attachable_type/:attachable_id' do
      resources :media
    end

    resources :media, only: [:index], as: :media_gallery

    get 'accounting-settings' => 'settings#index'
    patch 'accounting-settings' => 'settings#update'

    namespace :accounting do
      resources :quickbooks do
        collection do
          get :authenticate
          get :oauth_callback
          get :disconnect
          get :reset_data
          get :connected
          patch :update_changed
        end
      end

      resources :transactions, except: [:index, :destroy]
      resources :problem_loan_transactions, only: [:index, :show]
    end

    get '/basic-projects/:id/:tab' => 'basic_projects#show', as: 'basic_project_tab'
    get 'dashboard' => 'dashboard#dashboard', as: 'dashboard'
    get '/loans/:id/:tab' => 'loans#show', as: 'loan_tab'
    get '/loans/:project_id/transactions/:id' => 'accounting/transactions#show', as: 'loan_transaction'

    resources :documentations
  end

  localized do
    # :site can be 'argentina', 'nicaragua', or 'us'
    namespace :public, path: '/:site' do
      # We put a constraint on the format because otherwise, if the client doesn't supply an Accept
      # header (as with crawlers or uptime checkers), Rails has to search for a matching template,
      # and it fails to find one if the template gets generated after the app starts, probably because
      # the templates are loaded at app start time in production mode. If instead we restrict to one
      # format, Rails is able guess it successfully.
      constraints format: 'html' do
        resources :loans, only: [:index, :show]
      end
      get 'test' => 'static_pages#test'
      get 'update' => 'static_pages#update' # Manually update wordpress template
    end
  end

  scope module: :public, path: nil, as: :public do
    get '/division/:short_name' => 'divisions#show', as: :division
  end

  get '/ping', to: 'ping#index'

  root to: redirect(path: '/admin/dashboard')
end
