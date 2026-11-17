# frozen_string_literal: true

namespace :shops do
  desc "Reconcile every shop's variants and recent sales with Shopify"
  task sync: :environment do
    Shop.find_each { |shop| ShopSyncJob.perform_now(shop.id) }
  end
end
