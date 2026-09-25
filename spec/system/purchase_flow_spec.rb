require "rails_helper"

# The core loop end to end in a real browser: sign in, add to cart, check out,
# see the order. Nothing is stubbed -- it goes through Carts::CartService and
# Orders::CheckoutService exactly as a real user would.
RSpec.describe "Purchase flow", type: :system do
  let(:user) { create(:user, :with_cart) }
  let!(:product) { create(:product, stock: 10) }

  def add_to_cart(product)
    visit product_path(product)
    click_button "Add to Cart"
    find("#cart_count", text: "1") # wait for the Turbo Stream to land
  end

  def check_out
    visit cart_path
    find("a[href='#{new_checkout_path}']").click
    fill_in "Full Name", with: "Test User"
    fill_in "Address Line 1", with: "1 Spec Street"
    fill_in "City", with: "Specville"
    fill_in "State", with: "CA"
    fill_in "ZIP", with: "90210"
    click_button "Place Order"
    assert_current_path(%r{\A/orders/\d+\z}) # wait for the redirect
  end

  context "after signing in" do
    before { sign_in_via_ui(user) }

    it "lands on the storefront signed in" do
      expect(page).to have_current_path(root_path).and have_no_link(href: new_session_path)
    end
  end

  context "after adding a product to the cart" do
    before do
      sign_in_via_ui(user)
      add_to_cart(product)
      visit cart_path
    end

    it "lists the product in the cart" do
      expect(find("#cart_items")).to have_link(href: product_path(product))
    end
  end

  context "after checking out" do
    let(:order) { user.orders.last }

    before do
      sign_in_via_ui(user)
      add_to_cart(product)
      check_out
    end

    it "shows the new order" do
      expect(page).to have_current_path(order_path(order)).and have_link(href: product_path(product))
    end

    it "records the purchased product on the order" do
      expect(order.order_items.pluck(:product_id, :quantity)).to eq([ [ product.id, 1 ] ])
    end

    context "when visiting the orders page" do
      before { visit orders_path }

      it "lists the order" do
        expect(page).to have_link(href: order_path(order))
      end
    end
  end
end
