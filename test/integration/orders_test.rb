require "test_helper"

class OrdersTest < ActionDispatch::IntegrationTest
  test "a guest is redirected to sign in" do
    get orders_path

    assert_redirected_to new_session_path
  end

  test "index lists only the current user's orders" do
    sign_in_as users(:one)

    get orders_path

    assert_response :success
    assert_select "a[href=?]", order_path(orders(:one))
    assert_select "a[href=?]", order_path(orders(:two)), count: 0
  end

  test "show renders the current user's order" do
    sign_in_as users(:one)

    get order_path(orders(:one))

    assert_response :success
  end

  test "showing another user's order is a 404" do
    sign_in_as users(:one)

    get order_path(orders(:two))

    assert_response :not_found
  end
end
