require "application_system_test_case"

# Exercises the actual core loop this project is built around end-to-end
# through a real browser: sign in, add to cart, check out, see the order.
# Nothing here is stubbed -- it goes through CartService and
# Orders::CheckoutService exactly as a real user would.
class PurchaseFlowTest < ApplicationSystemTestCase
  test "a signed-in user can add a product to cart and complete checkout" do
    user = users(:one)
    product = products(:headphones)

    visit new_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Sign In"

    assert_text "Hello, #{user.name}"

    click_on product.name
    click_on "Add to Cart"

    assert_text "Added to cart."

    visit cart_path
    assert_text product.name

    click_on "Proceed to Checkout"

    fill_in "Full Name", with: "Alice Example"
    fill_in "Address Line 1", with: "1 Fixture Street"
    fill_in "City", with: "Fixtureville"
    fill_in "State", with: "CA"
    fill_in "ZIP", with: "90210"
    click_on "Place Order"

    assert_text "Order ##{Order.last.id}"
    assert_text product.name

    click_on "Orders"
    assert_text "Order #"
  end
end
