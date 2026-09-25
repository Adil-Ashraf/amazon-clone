require "test_helper"

class CartItemsTest < ActionDispatch::IntegrationTest
  TURBO_STREAM = { "Accept" => "text/vnd.turbo-stream.html, text/html, application/xhtml+xml" }.freeze

  test "a guest adding to cart is redirected to sign in" do
    assert_no_difference -> { CartItem.count } do
      post cart_items_path, params: { product_id: products(:novel).id }
    end

    assert_redirected_to new_session_path
  end

  test "a signed-in user adds to cart via turbo stream" do
    sign_in_as users(:one)

    assert_difference -> { carts(:one).cart_items.count }, 1 do
      post cart_items_path, params: { product_id: products(:novel).id, quantity: 2 }, headers: TURBO_STREAM
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_turbo_stream_targets "cart_count", "cart_items"
    assert_equal 2, carts(:one).cart_items.find_by(product: products(:novel)).quantity
  end

  test "adding a sold-out product responds without creating a line" do
    sign_in_as users(:one)

    assert_no_difference -> { CartItem.count } do
      post cart_items_path, params: { product_id: products(:sold_out).id }, headers: TURBO_STREAM
    end

    assert_response :success
    assert_turbo_stream_targets "cart_count", "cart_items"
  end

  test "PATCH updates the quantity" do
    sign_in_as users(:one)

    patch cart_item_path(cart_items(:one)), params: { quantity: 3 }, headers: TURBO_STREAM

    assert_response :success
    assert_turbo_stream_targets "cart_count", "cart_items"
    assert_equal 3, cart_items(:one).reload.quantity
  end

  test "PATCH above stock leaves the quantity unchanged" do
    sign_in_as users(:one)

    patch cart_item_path(cart_items(:one)), params: { quantity: 999 }, headers: TURBO_STREAM

    assert_response :success
    assert_equal 1, cart_items(:one).reload.quantity
  end

  test "DELETE removes the line" do
    sign_in_as users(:one)

    assert_difference -> { CartItem.count }, -1 do
      delete cart_item_path(cart_items(:one)), headers: TURBO_STREAM
    end

    assert_response :success
    assert_turbo_stream_targets "cart_count", "cart_items"
  end

  test "a user cannot PATCH another user's cart item" do
    sign_in_as users(:one)

    patch cart_item_path(cart_items(:two)), params: { quantity: 3 }, headers: TURBO_STREAM

    assert_response :not_found
    assert_equal 1, cart_items(:two).reload.quantity
  end

  test "a user cannot DELETE another user's cart item" do
    sign_in_as users(:one)

    assert_no_difference -> { CartItem.count } do
      delete cart_item_path(cart_items(:two)), headers: TURBO_STREAM
    end

    assert_response :not_found
  end

  private

  def assert_turbo_stream_targets(*targets)
    targets.each { |target| assert_select "turbo-stream[target=?]", target }
  end
end
