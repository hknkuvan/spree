Spree::Core::Engine.add_routes do
  namespace :admin, path: Spree.admin_path do
    # product catalog
    resources :properties, except: :show
    resources :option_types, except: :show do
      resources :option_values, only: [:update]
    end

    # media library
    resources :assets, only: [:create, :edit, :update, :destroy] do
      collection do
        delete :bulk_destroy
      end
    end

    # audit log
    resources :exports, only: %i[new create show index]

    # profile settings
    resource :profile, controller: 'profile', only: %i[edit update]

    # store settings
    resource :store, only: [:edit, :update], controller: 'stores' do
      member do
        get :edit_emails
      end
    end

    resources :payment_methods, except: :show
    resources :shipping_methods, except: :show
    resources :shipping_categories, except: :show
    resources :store_credit_categories
    resources :tax_rates, except: :show
    resources :tax_categories, except: :show
    resources :reimbursement_types
    resources :refund_reasons, except: :show
    resources :return_authorization_reasons, except: :show
    resources :zones
    resources :stock_locations, except: :show do
      member do
        put :mark_as_default
      end
    end

    # account management
    resources :roles, except: :show

    # developer tools
    resources :oauth_applications
    resources :webhooks_subscribers

    # orders
    resources :checkouts, only: %i[index]

    resources :orders, only: [:index, :edit, :create] do
      member do
        post :resend
        put :cancel
      end

      resource :shipping_address, except: [:index, :show], controller: 'orders/shipping_address'
      resource :billing_address, except: [:index, :show], controller: 'orders/billing_address'
      resource :contact_information, only: [:edit, :update], controller: 'orders/contact_information'
      resource :user, except: [:edit, :show, :index], controller: 'orders/user'
      resources :shipments, only: [:edit, :update, :create], controller: 'shipments' do
        member do
          post :ship
          get :split
          post :transfer
        end
      end
      resources :line_items, except: :show

      resources :customer_returns, only: [:index, :new, :edit, :create, :update] do
        member do
          put :refund
        end
      end

      resources :return_authorizations do
        member do
          put :cancel
        end
      end
      resources :payments, except: [:index, :show] do
        member do
          put :capture
          put :void
        end

        resources :refunds, only: [:new, :create, :edit, :update]
      end
      resources :payment_links, only: [:create], controller: 'orders/payment_links'

      resources :reimbursements, only: [:index, :create, :show, :edit, :update] do
        member do
          post :perform
        end
      end
    end

    # products
    resources :products do
      collection do
        get :select_options, defaults: { format: :json }
        post :search
        get :bulk_modal
        put :bulk_status_update
        put :bulk_add_to_taxons
        put :bulk_remove_from_taxons
        put :bulk_add_tags
        put :bulk_remove_tags
      end

      member do
        post :clone
      end

      resources :variants, only: [:edit, :update, :destroy]
      resources :digitals, only: [:index, :create, :destroy]
    end

    # stock
    resources :stock_items, only: [:index, :update, :destroy]
    resources :stock_transfers, except: [:edit, :update]

    # taxonomies and taxons
    resources :taxonomies do
      resources :taxons do
        member do
          put :reposition
        end
      end
    end

    resources :taxons, except: [:show] do |_taxon|
      resources :classifications, only: %i[index new create update destroy]
    end

    get '/taxons/select_options' => 'taxons#select_options', as: :taxons_select_options, defaults: { format: :json }

    # users
    resources :users

    # variants
    post 'variants/search'
    get 'variants/search', defaults: { format: :json }

    # errors
    get '/forbidden', to: 'errors#forbidden', as: :forbidden
  end
end
