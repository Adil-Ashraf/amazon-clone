require "test_helper"

class CheckoutTest < ActionDispatch::IntegrationTest
  SHIPPING = {
    shipping_name: "Alice Example",
    shipping_address_line1: "1 Fixture Street",
    shipping_city: "Fixtureville",
    shipping_state: "CA",
    shipping_zip: "90210"
  }.freeze

  setup { sign_in_as users(:one) }

  test "a guest is redirected to sign in" do
    delete session_path

    get new_checkout_path

    assert_redirected_to new_session_path
  end

  test "new renders when the cart has items" do
    get new_checkout_path

    assert_response :success
  end

  test "new with an empty cart redirects to the cart" do
    carts(:one).cart_items.destroy_all

    get new_checkout_path

    assert_redirected_to cart_path
  end

  test "create places an order and redirects to it" do
    assert_difference -> { users(:one).orders.count }, 1 do
      post checkout_path, params: { order: SHIPPING }
    end

    order = users(:one).orders.order(:created_at).last
    assert_redirected_to order_path(order)
    assert order.paid?
    assert_empty carts(:one).cart_items.reload
  end

  test "create with insufficient stock returns 422 and places no order" do
    cart_items(:one).update!(quantity: products(:headphones).stock)
    products(:headphones).update!(stock: 1)

    assert_no_difference -> { Order.count } do
      post checkout_path, params: { order: SHIPPING }
    end

    assert_response :unprocessable_entity
    assert_equal 1, products(:headphones).reload.stock
  end

  test "create with missing shipping details returns 422 and places no order" do
    assert_no_difference -> { Order.count } do
      post checkout_path, params: { order: SHIPPING.merge(shipping_city: "") }
    end

    assert_response :unprocessable_entity
    assert_equal 10, products(:headphones).reload.stock
  end
end
