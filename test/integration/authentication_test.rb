require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  test "sign up creates a user with a cart and signs them in" do
    assert_difference [ -> { User.count }, -> { Cart.count } ], 1 do
      post registration_path, params: {
        user: { name: "New User", email: "new@example.com", password: "password123", password_confirmation: "password123" }
      }
    end

    assert_redirected_to root_path
    user = User.find_by!(email: "new@example.com")
    assert user.cart.present?

    get cart_path
    assert_response :success
  end

  test "invalid sign up returns 422 and creates nothing" do
    assert_no_difference [ -> { User.count }, -> { Cart.count } ] do
      post registration_path, params: {
        user: { name: "", email: "bad", password: "short", password_confirmation: "nope" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "valid sign in redirects and grants access to the cart" do
    sign_in_as users(:one)

    assert_redirected_to root_path
    get cart_path
    assert_response :success
  end

  test "invalid sign in returns 422 and does not sign in" do
    sign_in_as users(:one), password: "wrong-password"

    assert_response :unprocessable_entity
    get cart_path
    assert_redirected_to new_session_path
  end

  test "sign out ends the session" do
    sign_in_as users(:one)

    delete session_path

    assert_redirected_to root_path
    get cart_path
    assert_redirected_to new_session_path
  end
end
