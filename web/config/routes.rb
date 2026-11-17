# frozen_string_literal: true

Rails.application.routes.draw do
  root to: "home#index"


  scope path: :api, format: :json do
    resources :products, only: :create do
      collection do
        get :count
      end
    end
    namespace :webhooks do
      post "/app_uninstalled", to: "app_uninstalled#receive"
      post "/app_scopes_update", to: "app_scopes_update#receive"
      post "/customers_data_request", to: "customers_data_request#receive"
      post "/customers_redact", to: "customers_redact#receive"
      post "/shop_redact", to: "shop_redact#receive"
      post "/orders_create", to: "orders_create#receive"
    end
  end

  mount ShopifyApp::Engine, at: "/api"
  get "/api", to: redirect(path: "/")


  match "*path" => "home#index", via: [:get, :post]
end
