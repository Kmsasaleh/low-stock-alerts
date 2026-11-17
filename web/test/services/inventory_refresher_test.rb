# frozen_string_literal: true

require "test_helper"

class InventoryRefresherTest < ActiveSupport::TestCase
  GID = "gid://shopify/ProductVariant/111"

  setup do
    @shop = Shop.create!(shopify_domain: "refresher-test.myshopify.com", shopify_token: "test-token")
    @variant = @shop.variants.create!(shopify_gid: GID, product_title: "Board", inventory_quantity: 48)
  end

  test "sets stock to Shopify's current total" do
    updated = refresh(item(tracked: true, nodes: [{ "id" => GID, "inventoryQuantity" => 46 }]))

    assert_equal 1, updated
    assert_equal 46, @variant.reload.inventory_quantity
  end

  test "asks Shopify for the inventory item in global ID format" do
    client = mock("admin_client")
    client.expects(:query)
      .with(query: InventoryRefresher::QUERY, variables: { id: "gid://shopify/InventoryItem/555" })
      .returns(stub(body: item(tracked: true, nodes: [])))

    InventoryRefresher.call(shop: @shop, inventory_item_id: 555, client: client)
  end

  test "leaves stock alone when the item is not tracked" do
    refresh(item(tracked: false, nodes: [{ "id" => GID, "inventoryQuantity" => 0 }]))

    assert_equal 48, @variant.reload.inventory_quantity
  end

  test "ignores variants this app does not store" do
    updated = refresh(item(tracked: true, nodes: [{ "id" => "gid://shopify/ProductVariant/999", "inventoryQuantity" => 5 }]))

    assert_equal 0, updated
  end

  test "raises when Shopify returns GraphQL errors" do
    assert_raises(InventoryRefresher::Error) do
      refresh({ "errors" => [{ "message" => "Throttled" }] })
    end
  end

  test "without an injected client it uses the shop's auto-refreshing session" do
    session = stub("session")
    client = mock("admin_client")
    client.stubs(:query).returns(stub(body: item(tracked: true, nodes: [{ "id" => GID, "inventoryQuantity" => 46 }])))
    @shop.expects(:with_shopify_session).yields(session)
    ShopifyAPI::Clients::Graphql::Admin.expects(:new).with(session: session).returns(client)

    InventoryRefresher.call(shop: @shop, inventory_item_id: 555)

    assert_equal 46, @variant.reload.inventory_quantity
  end

  private

  def refresh(body)
    client = mock("admin_client")
    client.stubs(:query).returns(stub(body: body))
    InventoryRefresher.call(shop: @shop, inventory_item_id: 555, client: client)
  end

  def item(tracked:, nodes:)
    { "data" => { "inventoryItem" => { "tracked" => tracked, "variants" => { "nodes" => nodes } } } }
  end
end
